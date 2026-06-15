import '../../core/clock.dart';
import '../../core/constants.dart';

enum BggEndpoint { thing, search }

class BggRateLimiter {
  BggRateLimiter({
    required Clock clock,
    required Sleeper sleeper,
    required Jitter jitter,
  }) : _clock = clock,
       _sleeper = sleeper,
       _jitter = jitter;

  final Clock _clock;
  final Sleeper _sleeper;
  final Jitter _jitter;
  final Map<BggEndpoint, List<DateTime>> _history = {
    BggEndpoint.thing: <DateTime>[],
    BggEndpoint.search: <DateTime>[],
  };

  Future<void> waitForTurn(BggEndpoint endpoint) async {
    final jitter = _jitter.betweenSeconds(
      AppConstants.requestJitterMinSeconds,
      AppConstants.requestJitterMaxSeconds,
    );
    if (jitter > Duration.zero) {
      await _sleeper.sleep(jitter);
    }

    final history = _history[endpoint]!;
    _prune(history);

    final limit = switch (endpoint) {
      BggEndpoint.thing => AppConstants.bggThingRateLimitPerMinute,
      BggEndpoint.search => AppConstants.bggSearchRateLimitPerMinute,
    };

    if (history.length >= limit) {
      final waitUntil = history.first.add(const Duration(seconds: 61));
      final wait = waitUntil.difference(_clock.now());
      if (wait > Duration.zero) {
        await _sleeper.sleep(wait);
      }
      _prune(history);
    }

    history.add(_clock.now());
  }

  void _prune(List<DateTime> history) {
    final threshold = _clock.now().subtract(const Duration(seconds: 61));
    history.removeWhere((sentAt) => !sentAt.isAfter(threshold));
  }
}
