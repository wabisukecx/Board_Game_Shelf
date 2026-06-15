import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import '../../core/clock.dart';
import '../../core/constants.dart';
import '../db/app_database.dart';
import 'bgg_token_provider.dart';
import 'bgg_transport.dart';
import 'bgg_xml_parser.dart';
import 'rate_limiter.dart';

class BggApiException implements Exception {
  const BggApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'BggApiException($statusCode): $message';
}

abstract interface class BggApi {
  Future<String> fetchThing({required String id, bool stats = true});

  Future<String> searchGames({required String query, bool exact = false});

  Future<String> collection({
    required String username,
    bool own = true,
    String subtype = AppConstants.bggCollectionSubtype,
  });
}

class BggApiClient implements BggApi {
  BggApiClient({
    required AppDatabase database,
    required BggTransport transport,
    required Clock clock,
    required Sleeper sleeper,
    required Jitter jitter,
    BggTokenProvider tokenProvider = const EmptyBggTokenProvider(),
  }) : _database = database,
       _transport = transport,
       _clock = clock,
       _sleeper = sleeper,
       _jitter = jitter,
       _tokenProvider = tokenProvider,
       _rateLimiter = BggRateLimiter(
         clock: clock,
         sleeper: sleeper,
         jitter: jitter,
       );

  final AppDatabase _database;
  final BggTransport _transport;
  final Clock _clock;
  final Sleeper _sleeper;
  final Jitter _jitter;
  final BggTokenProvider _tokenProvider;
  final BggRateLimiter _rateLimiter;
  Future<void> _tail = Future<void>.value();

  Future<String> fetchThing({required String id, bool stats = true}) {
    final cacheKey = 'bgg:thing:$id:stats=$stats';
    return _cachedRequest(
      cacheKey: cacheKey,
      ttl: AppConstants.thingCacheTtl,
      endpoint: BggEndpoint.thing,
      request: BggRequest(
        path: '/xmlapi2/thing',
        queryParameters: {'id': id, if (stats) 'stats': 1},
      ),
    );
  }

  Future<String> searchGames({required String query, bool exact = false}) {
    final normalizedQuery = BggXmlParser.normalizeSearchQuery(query);
    final cacheKey = 'bgg:search:$normalizedQuery:exact=$exact';
    return _cachedRequest(
      cacheKey: cacheKey,
      ttl: AppConstants.searchCacheTtl,
      endpoint: BggEndpoint.search,
      request: BggRequest(
        path: '/xmlapi2/search',
        queryParameters: {
          'query': normalizedQuery,
          'type': 'boardgame',
          if (exact) 'exact': 1,
        },
      ),
    );
  }

  @override
  Future<String> collection({
    required String username,
    bool own = true,
    String subtype = AppConstants.bggCollectionSubtype,
  }) {
    final normalized = username.trim();
    final ownValue = own ? AppConstants.bggCollectionOwn : 0;
    final cacheKey =
        'bgg:collection:$normalized:own=$ownValue:subtype=$subtype';
    return _cachedRequest(
      cacheKey: cacheKey,
      ttl: AppConstants.searchCacheTtl,
      endpoint: BggEndpoint.search,
      request: BggRequest(
        path: '/xmlapi2/collection',
        queryParameters: {
          'username': normalized,
          'own': ownValue,
          'subtype': subtype,
        },
      ),
    );
  }

  Future<String> _cachedRequest({
    required String cacheKey,
    required Duration ttl,
    required BggEndpoint endpoint,
    required BggRequest request,
  }) async {
    final cached = await _readCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    return _enqueue(() async {
      final secondLook = await _readCache(cacheKey);
      if (secondLook != null) {
        return secondLook;
      }

      final body = await _sendWithPolicy(endpoint, request);
      await _writeCache(cacheKey, body, ttl);
      return body;
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _tail = _tail.catchError((Object _) {});
    return completer.future;
  }

  Future<String> _sendWithPolicy(
    BggEndpoint endpoint,
    BggRequest request,
  ) async {
    var retry = 0;
    var acceptedRetries = 0;

    while (true) {
      await _rateLimiter.waitForTurn(endpoint);
      final BggResponse response;
      try {
        response = await _attempt(request);
      } on BggTransportException {
        if (retry >= AppConstants.maxRetryCount) {
          throw const BggApiException('Connection failed');
        }
        retry += 1;
        await _sleeper.sleep(_serverBackoff(retry));
        continue;
      }

      if (response.statusCode == 401) {
        throw const BggApiException('Unauthorized', statusCode: 401);
      }

      if (response.statusCode == 202) {
        if (acceptedRetries >= AppConstants.acceptedResponseMaxAttempts) {
          throw const BggApiException(
            'BGG response remained queued',
            statusCode: 202,
          );
        }
        acceptedRetries += 1;
        await _sleeper.sleep(
          const Duration(
            seconds: AppConstants.acceptedResponseRetryDelaySeconds,
          ),
        );
        continue;
      }

      if (response.statusCode == 429) {
        if (retry >= AppConstants.maxRetryCount) {
          throw const BggApiException('Rate limited', statusCode: 429);
        }
        retry += 1;
        await _sleeper.sleep(_retryAfterDelay(response));
        continue;
      }

      if (response.statusCode >= 500 && response.statusCode <= 599) {
        if (retry >= AppConstants.maxRetryCount) {
          throw BggApiException(
            'Server error',
            statusCode: response.statusCode,
          );
        }
        retry += 1;
        await _sleeper.sleep(_serverBackoff(retry));
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BggApiException(
          'Unexpected BGG response',
          statusCode: response.statusCode,
        );
      }

      return response.body;
    }
  }

  Future<BggResponse> _attempt(BggRequest request) async {
    try {
      final token = await _tokenProvider.readToken();
      if (token == null || token.isEmpty) {
        developer.log(
          'BGG bearer token is not configured; sending request without Authorization header.',
          name: 'bg_shelf_scanner.bgg',
        );
      }
      return await _transport.get(
        BggRequest(
          path: request.path,
          queryParameters: request.queryParameters,
          headers: {
            ...request.headers,
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
    } on BggTransportException {
      rethrow;
    } catch (error) {
      throw BggTransportException('$error');
    }
  }

  Duration _retryAfterDelay(BggResponse response) {
    final retryAfter = int.tryParse(response.header('retry-after') ?? '');
    final base = Duration(
      seconds: retryAfter ?? AppConstants.defaultRetryAfterSeconds,
    );
    return base +
        _jitter.betweenSeconds(
          AppConstants.retryAfterJitterMinSeconds.toDouble(),
          AppConstants.retryAfterJitterMaxSeconds.toDouble(),
        );
  }

  Duration _serverBackoff(int retry) {
    final seconds = math.pow(AppConstants.serverBackoffBase, retry).toInt();
    return Duration(seconds: seconds) +
        _jitter.betweenSeconds(
          AppConstants.serverBackoffJitterMinSeconds.toDouble(),
          AppConstants.serverBackoffJitterMaxSeconds.toDouble(),
        );
  }

  Future<String?> _readCache(String cacheKey) async {
    final entry = await (_database.select(
      _database.apiCacheEntries,
    )..where((table) => table.cacheKey.equals(cacheKey))).getSingleOrNull();
    if (entry == null) {
      return null;
    }
    if (!entry.expiresAt.isAfter(_clock.now())) {
      return null;
    }
    return entry.payload;
  }

  Future<void> _writeCache(String cacheKey, String payload, Duration ttl) {
    return _database
        .into(_database.apiCacheEntries)
        .insertOnConflictUpdate(
          ApiCacheEntriesCompanion.insert(
            cacheKey: cacheKey,
            payload: payload,
            expiresAt: _clock.now().add(ttl),
          ),
        );
  }
}
