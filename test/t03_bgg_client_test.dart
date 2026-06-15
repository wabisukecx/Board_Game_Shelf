import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/clock.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_api_client.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_token_provider.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_transport.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';

void main() {
  late FakeClock clock;
  late FakeSleeper sleeper;
  late AppDatabase database;
  late FakeTransport transport;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 6, 13));
    sleeper = FakeSleeper(clock);
    database = AppDatabase(NativeDatabase.memory());
    transport = FakeTransport(clock);
  });

  tearDown(() async {
    await database.close();
  });

  BggApiClient client({BggTokenProvider? tokenProvider, Jitter? jitter}) {
    return BggApiClient(
      database: database,
      transport: transport,
      clock: clock,
      sleeper: sleeper,
      jitter: jitter ?? const NoJitter(),
      tokenProvider: tokenProvider ?? const EmptyBggTokenProvider(),
    );
  }

  test('does not send the 16th detail request before 61 seconds', () async {
    transport.enqueueMany(
      List.generate(
        16,
        (index) => BggResponse(statusCode: 200, body: '<ok>$index</ok>'),
      ),
    );

    final api = client();
    for (var id = 1; id <= 16; id += 1) {
      await api.fetchThing(id: '$id');
    }

    expect(transport.sentAt, hasLength(16));
    expect(
      transport.sentAt[15].difference(transport.sentAt.first),
      greaterThanOrEqualTo(const Duration(seconds: 61)),
    );
  });

  test('uses cache before network and refetches after TTL', () async {
    transport.enqueue(const BggResponse(statusCode: 200, body: '<first/>'));
    transport.enqueue(const BggResponse(statusCode: 200, body: '<second/>'));

    final api = client();
    expect(await api.fetchThing(id: '13'), '<first/>');
    expect(await api.fetchThing(id: '13'), '<first/>');
    expect(transport.requests, hasLength(1));

    clock.advance(AppConstants.thingCacheTtl + const Duration(milliseconds: 1));

    expect(await api.fetchThing(id: '13'), '<second/>');
    expect(transport.requests, hasLength(2));
  });

  test('retries 429 with Retry-After header', () async {
    transport.enqueue(
      const BggResponse(
        statusCode: 429,
        body: 'limited',
        headers: {'Retry-After': '7'},
      ),
    );
    transport.enqueue(const BggResponse(statusCode: 200, body: '<ok/>'));

    expect(await client().searchGames(query: 'Catan'), '<ok/>');
    expect(sleeper.slept, contains(const Duration(seconds: 7)));
    expect(transport.requests, hasLength(2));
  });

  test('retries 429 without Retry-After using default wait', () async {
    transport.enqueue(const BggResponse(statusCode: 429, body: 'limited'));
    transport.enqueue(const BggResponse(statusCode: 200, body: '<ok/>'));

    expect(await client().searchGames(query: 'Catan'), '<ok/>');
    expect(
      sleeper.slept,
      contains(Duration(seconds: AppConstants.defaultRetryAfterSeconds)),
    );
  });

  test('retries 503 and connection errors with exponential backoff', () async {
    transport.enqueue(const BggResponse(statusCode: 503, body: 'down'));
    transport.enqueueError(const BggTransportException('timeout'));
    transport.enqueue(const BggResponse(statusCode: 200, body: '<ok/>'));

    expect(await client().fetchThing(id: '99'), '<ok/>');
    expect(sleeper.slept, contains(const Duration(seconds: 2)));
    expect(sleeper.slept, contains(const Duration(seconds: 4)));
    expect(transport.requests, hasLength(3));
  });

  test('retries 202 three times with fixed waits', () async {
    transport.enqueueMany([
      const BggResponse(statusCode: 202, body: 'queued'),
      const BggResponse(statusCode: 202, body: 'queued'),
      const BggResponse(statusCode: 202, body: 'queued'),
      const BggResponse(statusCode: 200, body: '<ready/>'),
    ]);

    expect(await client().fetchThing(id: '7'), '<ready/>');
    expect(
      sleeper.slept.where(
        (duration) =>
            duration ==
            const Duration(
              seconds: AppConstants.acceptedResponseRetryDelaySeconds,
            ),
      ),
      hasLength(3),
    );
    expect(transport.requests, hasLength(4));
  });

  test('does not retry 401', () async {
    transport.enqueue(const BggResponse(statusCode: 401, body: 'bad token'));

    await expectLater(
      client().fetchThing(id: '13'),
      throwsA(isA<BggApiException>()),
    );
    expect(transport.requests, hasLength(1));
  });

  test('adds bearer token when configured', () async {
    transport.enqueue(const BggResponse(statusCode: 200, body: '<ok/>'));

    await client(
      tokenProvider: const FixedTokenProvider('secret-token'),
    ).fetchThing(id: '13');

    expect(
      transport.requests.single.headers['Authorization'],
      'Bearer secret-token',
    );
  });

  test('normalizes search query whitespace to plus signs', () async {
    transport.enqueue(const BggResponse(statusCode: 200, body: '<ok/>'));

    await client().searchGames(query: '  Ark Nova  ');

    expect(transport.requests.single.queryParameters['query'], 'Ark+Nova');
  });

  test(
    'fetches collection with own and subtype parameters through 202 retry',
    () async {
      transport.enqueueMany([
        const BggResponse(statusCode: 202, body: 'queued'),
        const BggResponse(statusCode: 200, body: '<items/>'),
      ]);

      expect(await client().collection(username: '  player-one  '), '<items/>');

      expect(transport.requests, hasLength(2));
      expect(transport.requests.first.path, '/xmlapi2/collection');
      expect(
        transport.requests.first.queryParameters['username'],
        'player-one',
      );
      expect(
        transport.requests.first.queryParameters['own'],
        AppConstants.bggCollectionOwn,
      );
      expect(
        transport.requests.first.queryParameters['subtype'],
        AppConstants.bggCollectionSubtype,
      );
      expect(
        sleeper.slept,
        contains(
          const Duration(
            seconds: AppConstants.acceptedResponseRetryDelaySeconds,
          ),
        ),
      );
    },
  );
}

class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

class FakeSleeper implements Sleeper {
  FakeSleeper(this.clock);

  final FakeClock clock;
  final List<Duration> slept = [];

  @override
  Future<void> sleep(Duration duration) async {
    slept.add(duration);
    clock.advance(duration);
  }
}

class FakeTransport implements BggTransport {
  FakeTransport(this.clock);

  final FakeClock clock;
  final List<BggRequest> requests = [];
  final List<DateTime> sentAt = [];
  final List<Object> _queue = [];

  void enqueue(BggResponse response) => _queue.add(response);

  void enqueueError(Exception error) => _queue.add(error);

  void enqueueMany(Iterable<BggResponse> responses) => _queue.addAll(responses);

  @override
  Future<BggResponse> get(BggRequest request) async {
    requests.add(request);
    sentAt.add(clock.now());
    if (_queue.isEmpty) {
      return const BggResponse(statusCode: 200, body: '<default/>');
    }
    final next = _queue.removeAt(0);
    if (next is Exception) {
      throw next;
    }
    return next as BggResponse;
  }
}

class FixedTokenProvider implements BggTokenProvider {
  const FixedTokenProvider(this.token);

  final String token;

  @override
  Future<String?> readToken() async => token;
}
