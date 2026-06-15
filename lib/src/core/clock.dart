import 'dart:math';

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

abstract interface class Sleeper {
  Future<void> sleep(Duration duration);
}

class RealSleeper implements Sleeper {
  const RealSleeper();

  @override
  Future<void> sleep(Duration duration) => Future<void>.delayed(duration);
}

abstract interface class Jitter {
  Duration betweenSeconds(double min, double max);
}

class NoJitter implements Jitter {
  const NoJitter();

  @override
  Duration betweenSeconds(double min, double max) => Duration.zero;
}

/// Production jitter used by the running app. Tests inject [NoJitter] or a
/// deterministic fake instead, so the random implementation only ever runs on
/// device.
class RandomJitter implements Jitter {
  RandomJitter([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  Duration betweenSeconds(double min, double max) {
    if (max <= min) {
      return Duration(milliseconds: (min * 1000).round());
    }
    final seconds = min + _random.nextDouble() * (max - min);
    return Duration(milliseconds: (seconds * 1000).round());
  }
}
