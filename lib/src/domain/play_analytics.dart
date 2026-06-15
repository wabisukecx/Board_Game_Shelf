import '../core/constants.dart';
import '../data/repo/collection_repository.dart';
import '../data/repo/play_session_repository.dart';
import 'collection_analytics.dart';

class PlayAnalytics {
  const PlayAnalytics();

  PlayAnalyticsSummary summarize(
    List<CollectionListItem> items,
    List<PlaySessionRecord> sessions,
  ) {
    final analysisItems = collectionItemsForAnalysis(
      items,
      includeNotOwned: true,
    );
    final analysisGameKeys = {
      for (final item in analysisItems) item.game.gameKey,
    };
    final itemsByKey = {for (final item in items) item.game.gameKey: item};
    final actualTimes = <double>[];
    final actualVsNominal = <double>[];
    var actualTimeCount = 0;
    final mechanics = <String, int>{};
    final designers = <String, int>{};
    final mechanicRatings = <String, List<int>>{};
    final designerRatings = <String, List<int>>{};
    final expansionUsage = <String, int>{};
    final playerRatings = <int, List<int>>{};
    final gameRatings = <String, List<int>>{};

    final analysisSessions = [
      for (final session in sessions)
        if (analysisGameKeys.contains(session.gameKey)) session,
    ];

    for (final session in analysisSessions) {
      final item = itemsByKey[session.gameKey];
      final game = item?.game;
      final actualPlayingTime = session.actualPlayingTime;
      if (actualPlayingTime != null) {
        actualTimeCount += 1;
        actualTimes.add(actualPlayingTime.toDouble());
        final nominal = game?.playingTime;
        if (nominal != null) {
          actualVsNominal.add((actualPlayingTime - nominal).toDouble());
        }
      }

      if (game != null) {
        for (final mechanic in game.mechanics) {
          _increment(mechanics, mechanic);
          if (session.rating != null) {
            _append(mechanicRatings, mechanic, session.rating!);
          }
        }
        for (final designer in game.designers) {
          _increment(designers, designer);
          if (session.rating != null) {
            _append(designerRatings, designer, session.rating!);
          }
        }
      }

      for (final expansionGameKey in session.expansionGameKeys) {
        _increment(
          expansionUsage,
          _expansionLabel(itemsByKey, expansionGameKey),
        );
      }

      final playerCount = session.playerCount;
      if (playerCount != null &&
          session.rating != null &&
          playerCount >= AppConstants.analyticsMinPlayerCount &&
          playerCount <= AppConstants.analyticsMaxPlayerCount) {
        playerRatings.putIfAbsent(playerCount, () => []).add(session.rating!);
      }

      if (session.rating != null) {
        gameRatings.putIfAbsent(session.gameKey, () => []).add(session.rating!);
      }
    }

    return PlayAnalyticsSummary(
      totalSessions: analysisSessions.length,
      actualPlayingTime: NumericSummary.fromValues(
        actualTimes,
        totalCount: analysisSessions.length,
      ),
      actualPlayingTimeDistribution: _bucketPlayingTimes(
        analysisSessions,
        (session) => session.actualPlayingTime,
      ),
      actualVsNominalPlayingTime: NumericSummary.fromValues(
        actualVsNominal,
        totalCount: actualTimeCount,
      ),
      mechanicsPlayCounts: _topLabels(mechanics),
      designerPlayCounts: _topLabels(designers),
      mechanicRatings: _topRated(mechanicRatings),
      designerRatings: _topRated(designerRatings),
      expansionUsage: _topLabels(expansionUsage),
      ratingByPlayerCount: _ratedByPlayerCount(playerRatings),
      forgottenFavorites: _forgottenFavorites(itemsByKey, gameRatings),
    );
  }

  DistributionSummary _bucketPlayingTimes(
    List<PlaySessionRecord> sessions,
    int? Function(PlaySessionRecord session) select,
  ) {
    const labels = ['<=30', '31-60', '61-90', '91-120', '>120'];
    final counts = List<int>.filled(labels.length, 0);
    var included = 0;
    for (final session in sessions) {
      final value = select(session);
      if (value == null) {
        continue;
      }
      included += 1;
      counts[_playingTimeBucket(value)] += 1;
    }
    return DistributionSummary(
      entries: [
        for (var i = 0; i < labels.length; i += 1)
          CountEntry(label: labels[i], count: counts[i]),
      ],
      includedCount: included,
      excludedCount: sessions.length - included,
    );
  }

  int _playingTimeBucket(int value) {
    final edges = AppConstants.analyticsPlayingTimeBucketEdges;
    if (value <= edges[0]) return 0;
    if (value <= edges[1]) return 1;
    if (value <= edges[2]) return 2;
    if (value <= edges[3]) return 3;
    return 4;
  }

  List<CountEntry> _topLabels(Map<String, int> counts) {
    final entries =
        counts.entries
            .map((entry) => CountEntry(label: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) {
            final countOrder = b.count.compareTo(a.count);
            if (countOrder != 0) {
              return countOrder;
            }
            return a.label.compareTo(b.label);
          });
    return entries.take(AppConstants.analyticsTopN).toList(growable: false);
  }

  List<RatedEntry> _topRated(Map<String, List<int>> values) {
    final entries =
        values.entries
            .map(
              (entry) => RatedEntry(
                label: entry.key,
                average: _averageInts(entry.value),
                count: entry.value.length,
              ),
            )
            .toList()
          ..sort((a, b) {
            final averageOrder = b.average.compareTo(a.average);
            if (averageOrder != 0) {
              return averageOrder;
            }
            final countOrder = b.count.compareTo(a.count);
            if (countOrder != 0) {
              return countOrder;
            }
            return a.label.compareTo(b.label);
          });
    return entries.take(AppConstants.analyticsTopN).toList(growable: false);
  }

  List<RatedEntry> _ratedByPlayerCount(Map<int, List<int>> values) {
    final entries =
        values.entries
            .map(
              (entry) => RatedEntry(
                label: '${entry.key}',
                average: _averageInts(entry.value),
                count: entry.value.length,
              ),
            )
            .toList()
          ..sort((a, b) => int.parse(a.label).compareTo(int.parse(b.label)));
    return entries;
  }

  List<FavoriteEntry> _forgottenFavorites(
    Map<String, CollectionListItem> itemsByKey,
    Map<String, List<int>> values,
  ) {
    final entries = <FavoriteEntry>[];
    for (final entry in values.entries) {
      final item = itemsByKey[entry.key];
      final lastPlayedDate = item?.lastPlayedDate;
      if (item == null || lastPlayedDate == null) {
        continue;
      }
      final average = _averageInts(entry.value);
      if (average < AppConstants.playFavoriteRatingThreshold) {
        continue;
      }
      entries.add(
        FavoriteEntry(
          gameKey: entry.key,
          label: item.displayName,
          averageRating: average,
          lastPlayedDate: lastPlayedDate,
        ),
      );
    }
    entries.sort((a, b) {
      final dateOrder = a.lastPlayedDate.compareTo(b.lastPlayedDate);
      if (dateOrder != 0) {
        return dateOrder;
      }
      return a.label.compareTo(b.label);
    });
    return entries.take(AppConstants.analyticsTopN).toList(growable: false);
  }

  double _averageInts(List<int> values) {
    final sum = values.fold<int>(0, (total, value) => total + value);
    return sum / values.length;
  }

  void _increment(Map<String, int> counts, String value) {
    final label = value.trim();
    if (label.isEmpty) {
      return;
    }
    counts[label] = (counts[label] ?? 0) + 1;
  }

  void _append(Map<String, List<int>> values, String key, int value) {
    final label = key.trim();
    if (label.isEmpty) {
      return;
    }
    values.putIfAbsent(label, () => []).add(value);
  }

  String _expansionLabel(
    Map<String, CollectionListItem> itemsByKey,
    String gameKey,
  ) {
    return itemsByKey[gameKey]?.displayName ?? gameKey;
  }
}

class PlayAnalyticsSummary {
  const PlayAnalyticsSummary({
    required this.totalSessions,
    required this.actualPlayingTime,
    required this.actualPlayingTimeDistribution,
    required this.actualVsNominalPlayingTime,
    required this.mechanicsPlayCounts,
    required this.designerPlayCounts,
    required this.mechanicRatings,
    required this.designerRatings,
    required this.expansionUsage,
    required this.ratingByPlayerCount,
    required this.forgottenFavorites,
  });

  factory PlayAnalyticsSummary.empty() {
    return const PlayAnalyticsSummary(
      totalSessions: 0,
      actualPlayingTime: NumericSummary.empty(),
      actualPlayingTimeDistribution: DistributionSummary(
        entries: [],
        includedCount: 0,
        excludedCount: 0,
      ),
      actualVsNominalPlayingTime: NumericSummary.empty(),
      mechanicsPlayCounts: [],
      designerPlayCounts: [],
      mechanicRatings: [],
      designerRatings: [],
      expansionUsage: [],
      ratingByPlayerCount: [],
      forgottenFavorites: [],
    );
  }

  final int totalSessions;
  final NumericSummary actualPlayingTime;
  final DistributionSummary actualPlayingTimeDistribution;
  final NumericSummary actualVsNominalPlayingTime;
  final List<CountEntry> mechanicsPlayCounts;
  final List<CountEntry> designerPlayCounts;
  final List<RatedEntry> mechanicRatings;
  final List<RatedEntry> designerRatings;
  final List<CountEntry> expansionUsage;
  final List<RatedEntry> ratingByPlayerCount;
  final List<FavoriteEntry> forgottenFavorites;
}

class RatedEntry {
  const RatedEntry({
    required this.label,
    required this.average,
    required this.count,
  });

  final String label;
  final double average;
  final int count;
}

class FavoriteEntry {
  const FavoriteEntry({
    required this.gameKey,
    required this.label,
    required this.averageRating,
    required this.lastPlayedDate,
  });

  final String gameKey;
  final String label;
  final double averageRating;
  final String lastPlayedDate;
}
