import '../core/constants.dart';
import '../data/repo/collection_repository.dart';
import 'learning_curve.dart';

class CollectionAnalytics {
  const CollectionAnalytics();

  AnalyticsSummary summarize(
    List<CollectionListItem> source, {
    bool includeNotOwned = false,
    LearningCurveAnalyzer? analyzer,
  }) {
    final items = collectionItemsForAnalysis(
      source,
      includeNotOwned: includeNotOwned,
    );
    final localCount = items.where((item) => item.isLocal).length;
    final bggCount = items.length - localCount;
    final analyses = analyzer == null
        ? const <LearningCurveResult>[]
        : [for (final item in items) analyzer.analyze(item.game)];

    return AnalyticsSummary(
      totalCount: items.length,
      ownedCount: items.where((item) => item.collection.owned).length,
      notOwnedCount: items.where((item) => !item.collection.owned).length,
      baseCount: items
          .where((item) => item.game.gameKind == AppConstants.gameKindBase)
          .length,
      expansionCount: items
          .where((item) => item.game.gameKind == AppConstants.gameKindExpansion)
          .length,
      localCount: localCount,
      bggCount: bggCount,
      weight: _averageDouble(items, (item) => item.game.weight),
      rating: _averageParsedDouble(items, (item) => item.game.averageRating),
      initialBarrier: _averageAnalysis(
        analyses,
        (analysis) => analysis.initialBarrier,
        totalCount: items.length,
      ),
      strategicDepth: _averageAnalysis(
        analyses,
        (analysis) => analysis.strategicDepth,
        totalCount: items.length,
      ),
      replayability: _averageAnalysis(
        analyses,
        (analysis) => analysis.replayability,
        totalCount: items.length,
      ),
      purchasePrice: _priceSummary(items),
      weightDistribution: _bucketDoubles(
        items,
        (item) => item.game.weight,
        const ['<1.5', '1.5-2.5', '2.5-3.5', '3.5-4.5', '>=4.5'],
        (value) {
          final edges = AppConstants.analyticsWeightBucketEdges;
          if (value < edges[0]) return 0;
          if (value < edges[1]) return 1;
          if (value < edges[2]) return 2;
          if (value < edges[3]) return 3;
          return 4;
        },
      ),
      playingTimeDistribution: _bucketInts(
        items,
        (item) => item.game.playingTime,
        const ['<=30', '31-60', '61-90', '91-120', '>120'],
        (value) {
          final edges = AppConstants.analyticsPlayingTimeBucketEdges;
          if (value <= edges[0]) return 0;
          if (value <= edges[1]) return 1;
          if (value <= edges[2]) return 2;
          if (value <= edges[3]) return 3;
          return 4;
        },
      ),
      decadeDistribution: _bucketParsedInts(
        items,
        (item) => item.game.yearPublished,
        (value) => '${(value ~/ 10) * 10}s',
      ),
      ratingDistribution: _bucketParsedDoubles(
        items,
        (item) => item.game.averageRating,
        (value) => '${value.floor()}s',
      ),
      strategicDepthDistribution: _bucketAnalyses(
        analyses,
        const ['1.x', '2.x', '3.x', '4.x', '5.0'],
        (analysis) => analysis.strategicDepth,
        totalCount: items.length,
      ),
      learningCurveTypes: _topLabels(
        analyses.map(
          (analysis) => 'learning_curve.types.${analysis.learningCurveType}',
        ),
        limit: null,
      ),
      playerTypes: _topLabels(
        analyses.expand(
          (analysis) =>
              analysis.playerTypes.map((type) => 'player_types.$type'),
        ),
        limit: null,
      ),
      masteryTimes: _topLabels(
        analyses.map((analysis) => 'mastery_time.${analysis.masteryTime}'),
        limit: null,
      ),
      playerCoverage: _playerCoverage(items),
      mechanicsTop: _topLabels(items.expand((item) => item.game.mechanics)),
      categoriesTop: _topLabels(items.expand((item) => item.game.categories)),
      designersTop: _topLabels(items.expand((item) => item.game.designers)),
      publishersTop: _topLabels(items.expand((item) => item.game.publishers)),
      storageLocations: _topLabels(
        items.map((item) => item.collection.storageLocation),
        limit: null,
        emptyLabel: CountEntry.unspecifiedLabel,
      ),
      acquisitionsByMonth: _acquisitionsByMonth(items),
    );
  }

  NumericSummary _averageAnalysis(
    List<LearningCurveResult> analyses,
    double Function(LearningCurveResult analysis) select, {
    required int totalCount,
  }) {
    return NumericSummary.fromValues([
      for (final analysis in analyses) select(analysis),
    ], totalCount: totalCount);
  }

  DistributionSummary _bucketAnalyses(
    List<LearningCurveResult> analyses,
    List<String> labels,
    double Function(LearningCurveResult analysis) select, {
    required int totalCount,
  }) {
    final counts = List<int>.filled(labels.length, 0);
    for (final analysis in analyses) {
      final value = select(analysis);
      final index = value >= 5.0 ? 4 : (value.floor() - 1).clamp(0, 4);
      counts[index] += 1;
    }
    return DistributionSummary(
      entries: [
        for (var i = 0; i < labels.length; i += 1)
          CountEntry(label: labels[i], count: counts[i]),
      ],
      includedCount: analyses.length,
      excludedCount: totalCount - analyses.length,
    );
  }

  NumericSummary _averageDouble(
    List<CollectionListItem> items,
    double? Function(CollectionListItem item) select,
  ) {
    final values = <double>[];
    for (final item in items) {
      final value = select(item);
      if (value != null) {
        values.add(value);
      }
    }
    return NumericSummary.fromValues(values, totalCount: items.length);
  }

  NumericSummary _averageParsedDouble(
    List<CollectionListItem> items,
    String? Function(CollectionListItem item) select,
  ) {
    final values = <double>[];
    for (final item in items) {
      final value = double.tryParse(select(item) ?? '');
      if (value != null) {
        values.add(value);
      }
    }
    return NumericSummary.fromValues(values, totalCount: items.length);
  }

  PriceSummary _priceSummary(List<CollectionListItem> items) {
    final values = <double>[];
    for (final item in items) {
      final value = item.collection.purchasePrice;
      if (value != null) {
        values.add(value);
      }
    }
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return PriceSummary(
      sum: total,
      average: values.isEmpty ? null : total / values.length,
      includedCount: values.length,
      excludedCount: items.length - values.length,
    );
  }

  DistributionSummary _bucketDoubles(
    List<CollectionListItem> items,
    double? Function(CollectionListItem item) select,
    List<String> labels,
    int Function(double value) bucket,
  ) {
    final counts = List<int>.filled(labels.length, 0);
    var included = 0;
    for (final item in items) {
      final value = select(item);
      if (value == null) {
        continue;
      }
      included += 1;
      counts[bucket(value)] += 1;
    }
    return DistributionSummary(
      entries: [
        for (var i = 0; i < labels.length; i += 1)
          CountEntry(label: labels[i], count: counts[i]),
      ],
      includedCount: included,
      excludedCount: items.length - included,
    );
  }

  DistributionSummary _bucketInts(
    List<CollectionListItem> items,
    int? Function(CollectionListItem item) select,
    List<String> labels,
    int Function(int value) bucket,
  ) {
    final counts = List<int>.filled(labels.length, 0);
    var included = 0;
    for (final item in items) {
      final value = select(item);
      if (value == null) {
        continue;
      }
      included += 1;
      counts[bucket(value)] += 1;
    }
    return DistributionSummary(
      entries: [
        for (var i = 0; i < labels.length; i += 1)
          CountEntry(label: labels[i], count: counts[i]),
      ],
      includedCount: included,
      excludedCount: items.length - included,
    );
  }

  DistributionSummary _bucketParsedInts(
    List<CollectionListItem> items,
    String? Function(CollectionListItem item) select,
    String Function(int value) label,
  ) {
    final counts = <String, int>{};
    var included = 0;
    for (final item in items) {
      final value = int.tryParse(select(item) ?? '');
      if (value == null) {
        continue;
      }
      included += 1;
      final key = label(value);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries =
        counts.entries
            .map((entry) => CountEntry(label: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    return DistributionSummary(
      entries: entries,
      includedCount: included,
      excludedCount: items.length - included,
    );
  }

  DistributionSummary _bucketParsedDoubles(
    List<CollectionListItem> items,
    String? Function(CollectionListItem item) select,
    String Function(double value) label,
  ) {
    final counts = <String, int>{};
    var included = 0;
    for (final item in items) {
      final value = double.tryParse(select(item) ?? '');
      if (value == null) {
        continue;
      }
      included += 1;
      final key = label(value);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries =
        counts.entries
            .map((entry) => CountEntry(label: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    return DistributionSummary(
      entries: entries,
      includedCount: included,
      excludedCount: items.length - included,
    );
  }

  DistributionSummary _playerCoverage(List<CollectionListItem> items) {
    final entries = <CountEntry>[];
    var included = 0;
    var excluded = 0;
    final countable = <CollectionListItem>[];
    for (final item in items) {
      final min = item.game.publisherMinPlayers;
      final max = item.game.publisherMaxPlayers;
      if (min == null || max == null) {
        excluded += 1;
        continue;
      }
      included += 1;
      countable.add(item);
    }
    for (
      var players = AppConstants.analyticsMinPlayerCount;
      players <= AppConstants.analyticsMaxPlayerCount;
      players += 1
    ) {
      final count = countable.where((item) {
        final min = item.game.publisherMinPlayers!;
        final max = item.game.publisherMaxPlayers!;
        return min <= players && players <= max;
      }).length;
      entries.add(CountEntry(label: '$players', count: count));
    }
    return DistributionSummary(
      entries: entries,
      includedCount: included,
      excludedCount: excluded,
    );
  }

  List<CountEntry> _topLabels(
    Iterable<String?> values, {
    int? limit = AppConstants.analyticsTopN,
    String? emptyLabel,
  }) {
    final counts = <String, int>{};
    for (final value in values) {
      final label = value?.trim();
      final key = label == null || label.isEmpty ? emptyLabel : label;
      if (key == null) {
        continue;
      }
      counts[key] = (counts[key] ?? 0) + 1;
    }
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
    if (limit == null || entries.length <= limit) {
      return entries;
    }
    return entries.take(limit).toList(growable: false);
  }

  DistributionSummary _acquisitionsByMonth(List<CollectionListItem> items) {
    final counts = <String, int>{};
    var included = 0;
    for (final item in items) {
      final parsed = DateTime.tryParse(item.collection.acquiredDate ?? '');
      if (parsed == null) {
        continue;
      }
      included += 1;
      final key =
          '${parsed.year.toString().padLeft(4, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries =
        counts.entries
            .map((entry) => CountEntry(label: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    return DistributionSummary(
      entries: entries,
      includedCount: included,
      excludedCount: items.length - included,
    );
  }
}

List<CollectionListItem> collectionItemsForAnalysis(
  List<CollectionListItem> source, {
  bool includeNotOwned = false,
}) {
  return [
    for (final item in source)
      if ((includeNotOwned || item.collection.owned) &&
          item.game.gameKind == AppConstants.gameKindBase)
        item,
  ];
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalCount,
    required this.ownedCount,
    required this.notOwnedCount,
    required this.baseCount,
    required this.expansionCount,
    required this.localCount,
    required this.bggCount,
    required this.weight,
    required this.rating,
    required this.initialBarrier,
    required this.strategicDepth,
    required this.replayability,
    required this.purchasePrice,
    required this.weightDistribution,
    required this.playingTimeDistribution,
    required this.decadeDistribution,
    required this.ratingDistribution,
    required this.strategicDepthDistribution,
    required this.learningCurveTypes,
    required this.playerTypes,
    required this.masteryTimes,
    required this.playerCoverage,
    required this.mechanicsTop,
    required this.categoriesTop,
    required this.designersTop,
    required this.publishersTop,
    required this.storageLocations,
    required this.acquisitionsByMonth,
  });

  factory AnalyticsSummary.empty() {
    const emptyDistribution = DistributionSummary(
      entries: [],
      includedCount: 0,
      excludedCount: 0,
    );
    return const AnalyticsSummary(
      totalCount: 0,
      ownedCount: 0,
      notOwnedCount: 0,
      baseCount: 0,
      expansionCount: 0,
      localCount: 0,
      bggCount: 0,
      weight: NumericSummary.empty(),
      rating: NumericSummary.empty(),
      initialBarrier: NumericSummary.empty(),
      strategicDepth: NumericSummary.empty(),
      replayability: NumericSummary.empty(),
      purchasePrice: PriceSummary.empty(),
      weightDistribution: emptyDistribution,
      playingTimeDistribution: emptyDistribution,
      decadeDistribution: emptyDistribution,
      ratingDistribution: emptyDistribution,
      strategicDepthDistribution: emptyDistribution,
      learningCurveTypes: [],
      playerTypes: [],
      masteryTimes: [],
      playerCoverage: emptyDistribution,
      mechanicsTop: [],
      categoriesTop: [],
      designersTop: [],
      publishersTop: [],
      storageLocations: [],
      acquisitionsByMonth: emptyDistribution,
    );
  }

  final int totalCount;
  final int ownedCount;
  final int notOwnedCount;
  final int baseCount;
  final int expansionCount;
  final int localCount;
  final int bggCount;
  final NumericSummary weight;
  final NumericSummary rating;
  final NumericSummary initialBarrier;
  final NumericSummary strategicDepth;
  final NumericSummary replayability;
  final PriceSummary purchasePrice;
  final DistributionSummary weightDistribution;
  final DistributionSummary playingTimeDistribution;
  final DistributionSummary decadeDistribution;
  final DistributionSummary ratingDistribution;
  final DistributionSummary strategicDepthDistribution;
  final List<CountEntry> learningCurveTypes;
  final List<CountEntry> playerTypes;
  final List<CountEntry> masteryTimes;
  final DistributionSummary playerCoverage;
  final List<CountEntry> mechanicsTop;
  final List<CountEntry> categoriesTop;
  final List<CountEntry> designersTop;
  final List<CountEntry> publishersTop;
  final List<CountEntry> storageLocations;
  final DistributionSummary acquisitionsByMonth;
}

class NumericSummary {
  const NumericSummary({
    required this.average,
    required this.includedCount,
    required this.excludedCount,
  });

  const NumericSummary.empty()
    : average = null,
      includedCount = 0,
      excludedCount = 0;

  factory NumericSummary.fromValues(
    List<double> values, {
    required int totalCount,
  }) {
    final sum = values.fold<double>(0, (total, value) => total + value);
    return NumericSummary(
      average: values.isEmpty ? null : sum / values.length,
      includedCount: values.length,
      excludedCount: totalCount - values.length,
    );
  }

  final double? average;
  final int includedCount;
  final int excludedCount;
}

class PriceSummary {
  const PriceSummary({
    required this.sum,
    required this.average,
    required this.includedCount,
    required this.excludedCount,
  });

  const PriceSummary.empty()
    : sum = 0,
      average = null,
      includedCount = 0,
      excludedCount = 0;

  final double sum;
  final double? average;
  final int includedCount;
  final int excludedCount;
}

class DistributionSummary {
  const DistributionSummary({
    required this.entries,
    required this.includedCount,
    required this.excludedCount,
  });

  final List<CountEntry> entries;
  final int includedCount;
  final int excludedCount;
}

class CountEntry {
  const CountEntry({required this.label, required this.count});

  static const unspecifiedLabel = '__unspecified__';

  final String label;
  final int count;
}
