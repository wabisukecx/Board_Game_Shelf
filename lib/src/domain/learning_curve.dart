import 'dart:math' as math;

import '../core/clock.dart';
import '../core/constants.dart';
import '../data/db/app_database.dart';
import 'complexity_tables.dart';
import 'game_rank.dart';

class LearningCurveAnalyzer {
  const LearningCurveAnalyzer({required this.tables, required this.clock});

  final ComplexityTables tables;
  final Clock clock;

  LearningCurveResult analyze(Game game) {
    final mechanics = game.mechanics;
    final categories = game.categories;
    final weight = game.weight ?? AppConstants.defaultGameWeight;
    final mechanicComplexity = _averageMechanicComplexity(mechanics);
    final categoryComplexity = tables.calculateCategoryComplexity(categories);
    final rankComplexity = tables.calculateRankComplexity(game.ranks);
    final complexityFactor = categoryComplexity * 0.6 + rankComplexity * 0.4;
    final strategic = _calculateStrategicDepth(game);
    final initialBarrier = roundScore(
      math.min(
        AppConstants.analysisMaxScore,
        (mechanicComplexity * 0.40 +
                strategic.rulesComplexity * 0.25 +
                weight * 0.20 +
                complexityFactor * 0.15) *
            math.min(1.25, math.max(1.0, mechanics.length / 5)),
      ),
    );
    final replayability = _calculateReplayability(game);
    final playerTypes = _playerTypes(
      game: game,
      initialBarrier: initialBarrier,
      strategicDepth: strategic.strategicDepth,
      replayability: replayability,
    );

    return LearningCurveResult(
      initialBarrier: initialBarrier,
      strategicDepth: strategic.strategicDepth,
      replayability: replayability,
      decisionPoints: roundScore(strategic.decisionPoints),
      interactionComplexity: roundScore(strategic.interactionComplexity),
      rulesComplexity: roundScore(strategic.rulesComplexity),
      mechanicComplexity: roundScore(mechanicComplexity),
      soloSuitability: roundScore(_soloFriendliness(game)),
      playerScalability: roundScore(_playerScalability(game)),
      luckDependence: roundScore(_luckDependency(mechanics)),
      learningCurveType: _learningCurveType(
        initialBarrier,
        strategic.strategicDepth,
      ),
      playerTypes: playerTypes,
      masteryTime: _masteryTime(
        initialBarrier: initialBarrier,
        strategicDepth: strategic.strategicDepth,
        mechanicCount: mechanics.length,
      ),
      strategicDepthLabel: strategicDepthLabel(strategic.strategicDepth),
      replayabilityLabel: replayabilityLabel(replayability),
      categoryComplexity: roundScore(categoryComplexity),
      rankComplexity: roundScore(rankComplexity),
    );
  }

  double _averageMechanicComplexity(List<String> mechanics) {
    if (mechanics.isEmpty) {
      return AppConstants.defaultGameWeight;
    }
    return mechanics
            .map((name) => tables.mechanic(name).complexity)
            .fold<double>(0, (sum, value) => sum + value) /
        mechanics.length;
  }

  _StrategicDepth _calculateStrategicDepth(Game game) {
    final weight = game.weight ?? AppConstants.defaultGameWeight;
    final playtime = _evaluatePlaytimeComplexity(game);
    final decisionPoints = _estimateDecisionPoints(game, playtime);
    final interactionComplexity = _estimateInteractionComplexity(
      game,
      playtime,
    );
    final rulesComplexity = _calculateRulesComplexity(game);
    final strategyValues = [
      for (final mechanic in game.mechanics)
        MapEntry(mechanic, tables.mechanic(mechanic).strategicValue),
    ]..sort((a, b) => b.value.compareTo(a.value));
    var strategyBonus = 0.0;
    if (strategyValues.isNotEmpty) {
      final topN = math.min(3, strategyValues.length);
      final weights = [0.5, 0.3, 0.2].take(topN).toList();
      final weightSum = weights.fold<double>(0, (sum, value) => sum + value);
      for (var i = 0; i < topN; i += 1) {
        final impact = 0.1 * (strategyValues[i].value - 2.5);
        strategyBonus += impact * (weights[i] / weightSum);
      }
      final decayFactor =
          1.0 / (1.0 + math.log(strategyValues.length) / math.ln10);
      strategyBonus = math.min(0.8, strategyBonus * decayFactor);
    }
    const hiddenInfoMechanics = {
      'Roles with Asymmetric Information',
      'Secret Unit Deployment',
      'Betting and Bluffing',
      'Hidden Victory Points',
      'Closed Drafting',
      'Communication Limits',
      'Deduction',
      'Predictive Bid',
    };
    final hiddenInfoBonus = math.min(
      0.3,
      game.mechanics.where(hiddenInfoMechanics.contains).length * 0.1,
    );
    final strategicDepth =
        weight * 0.30 +
        decisionPoints * 0.35 +
        rulesComplexity * 0.10 +
        interactionComplexity * 0.25 +
        math.min(0.4, strategyBonus) +
        math.min(0.1, playtime.strategicBonus * 0.6) +
        hiddenInfoBonus;
    return _StrategicDepth(
      strategicDepth: roundScore(clampScore(strategicDepth)),
      decisionPoints: decisionPoints,
      interactionComplexity: interactionComplexity,
      rulesComplexity: rulesComplexity,
    );
  }

  double _estimateDecisionPoints(Game game, _PlaytimeAnalysis playtime) {
    if (game.mechanics.isEmpty) {
      return 2.5;
    }
    final values = [
      for (final mechanic in game.mechanics)
        tables.mechanic(mechanic).strategicValue,
    ]..sort((a, b) => b.compareTo(a));
    final weights = _decisionWeights(values.length);
    final weighted = _weighted(values, weights);
    final uniqueValues = values.toSet();
    final valueRange = values.length > 1 ? values.first - values.last : 0.0;
    final diversityBonus = math.min(
      0.4,
      uniqueValues.length * 0.07 + valueRange * 0.1,
    );
    final adjusted =
        (weighted + diversityBonus + playtime.decisionDensity * 0.8) *
        (1.0 + (playtime.complexityFactor - 1.0) * 0.9);
    return clampScore(adjusted);
  }

  double _estimateInteractionComplexity(Game game, _PlaytimeAnalysis playtime) {
    if (game.categories.isEmpty && game.mechanics.isEmpty) {
      return 2.5;
    }
    final categoryValues = [
      for (final category in game.categories)
        _categoryInteractionValue(category),
    ];
    final mechanicValues = [
      for (final mechanic in game.mechanics)
        _mechanicInteractionValue(mechanic),
    ];
    late final List<double> values;
    late final List<double> weights;
    if (categoryValues.isNotEmpty && mechanicValues.isNotEmpty) {
      final weightedValues = [
        for (final value in categoryValues)
          MapEntry(value, 0.6 / categoryValues.length),
        for (final value in mechanicValues)
          MapEntry(value, 0.4 / mechanicValues.length),
      ]..sort((a, b) => b.key.compareTo(a.key));
      values = [for (final entry in weightedValues) entry.key];
      weights = [for (final entry in weightedValues) entry.value];
    } else {
      values = [...categoryValues, ...mechanicValues]
        ..sort((a, b) => b.compareTo(a));
      weights = _interactionWeights(values.length);
    }
    var interaction = _weighted(values, weights);
    interaction += playtime.interactionModifier * 0.85;
    interaction *= 1.0 + (playtime.complexityFactor - 1.0) * 0.9;
    final maxPlayers =
        game.publisherMaxPlayers ?? AppConstants.defaultGameMaxPlayers;
    if (maxPlayers >= 5) {
      interaction *= 1.10;
    } else if (maxPlayers >= 4) {
      interaction *= 1.07;
    }
    return clampScore(interaction);
  }

  double _calculateRulesComplexity(Game game) {
    final avgMechanicComplexity = _averageMechanicComplexity(game.mechanics);
    final mechanicsCountFactor = math.min(
      1.5,
      1.0 + game.mechanics.length / 10,
    );
    final minAge = (game.publisherMinAge ?? AppConstants.defaultGameMinAge)
        .toDouble();
    final ageComplexity = math.min(4.0, (minAge - 6) / 3);
    final weight = game.weight ?? AppConstants.defaultGameWeight;
    return clampScore(
      (avgMechanicComplexity * mechanicsCountFactor) * 0.6 +
          ageComplexity * 0.2 +
          weight * 0.2,
    );
  }

  double _calculateReplayability(Game game) {
    var diversityScore = math.min(0.7, game.mechanics.length * 0.1);
    const highReplayMechanics = {
      'Variable Set-up',
      'Modular Board',
      'Variable Player Powers',
      'Deck Building',
      'Campaign / Battle Card Driven',
      'Scenario / Mission / Campaign Game',
      'Deck Construction',
      'Engine Building',
      'Hidden Roles',
      'Asymmetric Gameplay',
    };
    const mediumReplayMechanics = {
      'Card Drafting',
      'Worker Placement',
      'Tech Trees / Tech Tracks',
      'Multi-Use Cards',
      'Area Control',
      'Route/Network Building',
      'Tile Placement',
      'Resource Management',
      'Drafting',
    };
    final highReplayCount = game.mechanics
        .where(highReplayMechanics.contains)
        .length;
    final mediumReplayCount = game.mechanics
        .where(mediumReplayMechanics.contains)
        .length;
    diversityScore += math.min(
      0.8,
      highReplayCount * 0.2 + mediumReplayCount * 0.1,
    );
    diversityScore += math.min(0.4, game.categories.length * 0.1);
    final rank = _rankValue(game.ranks);
    var rankBonus = 0.0;
    if (rank != null) {
      rankBonus = math.min(
        0.6,
        math.max(
          0.0,
          (tables.calculateRankPositionScore(rank) - 1.0) / 4.0 * 0.6,
        ),
      );
    }
    final playTime = game.playingTime ?? AppConstants.defaultGamePlayingTime;
    final playtimeReplayBonus = switch (playTime) {
      <= 30 => 0.3,
      <= 60 => 0.15,
      >= 180 => -0.2,
      _ => 0.0,
    };
    final replayability =
        (2.0 + diversityScore + rankBonus) *
            _longevityFactor(_yearPublished(game), isRanked: rank != null) +
        playtimeReplayBonus;
    return roundScore(clampScore(replayability));
  }

  _PlaytimeAnalysis _evaluatePlaytimeComplexity(Game game) {
    final playTime = game.playingTime;
    if (playTime == null) {
      return const _PlaytimeAnalysis();
    }
    var strategicBonus = 0.0;
    var interactionModifier = 0.0;
    var decisionDensity = 0.0;
    var complexityFactor = 1.0;
    if (playTime > 180) {
      strategicBonus = 0.3;
    } else if (playTime > 120) {
      strategicBonus = 0.2;
    } else if (playTime > 60) {
      strategicBonus = 0.1;
    }
    if (playTime <= 30) {
      interactionModifier = 0.2;
    } else if (playTime >= 180) {
      interactionModifier = 0.1;
    }
    final mechanicsCount = game.mechanics.length;
    if (playTime <= 30 && mechanicsCount >= 3) {
      decisionDensity = 0.2;
    } else if (playTime <= 60 && mechanicsCount >= 4) {
      decisionDensity = 0.15;
    } else if (playTime <= 120 && mechanicsCount >= 5) {
      decisionDensity = 0.1;
    }
    if (playTime < 20) {
      complexityFactor = 0.85;
    } else if (playTime < 45) {
      complexityFactor = 0.95;
    } else if (playTime > 180) {
      complexityFactor = 1.1;
    }
    return _PlaytimeAnalysis(
      strategicBonus: strategicBonus,
      interactionModifier: interactionModifier,
      decisionDensity: decisionDensity,
      complexityFactor: complexityFactor,
    );
  }

  double _mechanicInteractionValue(String mechanic) {
    final entry = tables.mechanics[mechanic];
    if (entry != null) {
      return entry.interactionValue;
    }
    const highInteraction = {
      'Trading',
      'Negotiation',
      'Auction/Bidding',
      'Take That',
      'Betting and Bluffing',
      'Player Elimination',
    };
    const mediumInteraction = {
      'Area Control',
      'Team-Based Game',
      'Cooperative Game',
      'Simultaneous Action Selection',
    };
    if (highInteraction.contains(mechanic)) {
      return 4.5;
    }
    if (mediumInteraction.contains(mechanic)) {
      return 3.8;
    }
    return AppConstants.fallbackMechanicInteractionValue;
  }

  double _categoryInteractionValue(String category) {
    final entry = tables.categories[category];
    if (entry != null) {
      return entry.interactionValue;
    }
    const highInteraction = {
      'Negotiation',
      'Political',
      'Bluffing',
      'Party Game',
      'Fighting',
    };
    const lowInteraction = {
      'Abstract Strategy',
      'Puzzle',
      'Solo / Solitaire Game',
    };
    if (highInteraction.contains(category)) {
      return 4.5;
    }
    if (lowInteraction.contains(category)) {
      return 2.0;
    }
    return AppConstants.fallbackMechanicInteractionValue;
  }

  double _soloFriendliness(Game game) {
    final mechanics = game.mechanics.toSet();
    if (mechanics.contains('Solo / Solitaire Game')) {
      return 5.0;
    }
    if (mechanics.contains('Cooperative Game')) {
      return 4.0;
    }
    if (mechanics.contains('Scenario / Mission / Campaign Game')) {
      return 3.5;
    }
    return (game.publisherMinPlayers ?? AppConstants.defaultGameMinPlayers) == 1
        ? 3.0
        : 1.0;
  }

  double _playerScalability(Game game) {
    final minPlayers =
        game.publisherMinPlayers ?? AppConstants.defaultGameMinPlayers;
    final maxPlayers =
        game.publisherMaxPlayers ?? AppConstants.defaultGameMaxPlayers;
    return math.min(5.0, 2.0 + math.max(0, maxPlayers - minPlayers) * 0.5);
  }

  double _luckDependency(List<String> mechanics) {
    const highLuck = {
      'Dice Rolling',
      'Random Production',
      'Push Your Luck',
      'Roll / Spin and Move',
      'Chit-Pull System',
      'Critical Hits and Failures',
    };
    const lowLuck = {
      'Worker Placement',
      'Engine Building',
      'Tech Trees / Tech Tracks',
      'Deck Construction',
      'Action Points',
    };
    final luckCount = mechanics.where(highLuck.contains).length;
    final strategyCount = mechanics.where(lowLuck.contains).length;
    return clampScore(3.0 + luckCount * 0.5 - strategyCount * 0.4);
  }

  double _longevityFactor(int? yearPublished, {required bool isRanked}) {
    if (yearPublished == null || !isRanked) {
      return 1.0;
    }
    final years = clock.now().year - yearPublished;
    if (years >= 20) {
      return 1.1;
    }
    if (years >= 10) {
      return 1.07;
    }
    if (years >= 5) {
      return 1.05;
    }
    return 1.0;
  }
}

class LearningCurveResult {
  const LearningCurveResult({
    required this.initialBarrier,
    required this.strategicDepth,
    required this.replayability,
    required this.decisionPoints,
    required this.interactionComplexity,
    required this.rulesComplexity,
    required this.mechanicComplexity,
    required this.soloSuitability,
    required this.playerScalability,
    required this.luckDependence,
    required this.learningCurveType,
    required this.playerTypes,
    required this.masteryTime,
    required this.strategicDepthLabel,
    required this.replayabilityLabel,
    required this.categoryComplexity,
    required this.rankComplexity,
  });

  final double initialBarrier;
  final double strategicDepth;
  final double replayability;
  final double decisionPoints;
  final double interactionComplexity;
  final double rulesComplexity;
  final double mechanicComplexity;
  final double soloSuitability;
  final double playerScalability;
  final double luckDependence;
  final String learningCurveType;
  final List<String> playerTypes;
  final String masteryTime;
  final String strategicDepthLabel;
  final String replayabilityLabel;
  final double categoryComplexity;
  final double rankComplexity;
}

String strategicDepthLabel(double value) {
  if (value >= 4.5) return 'very_deep';
  if (value >= 4.0) return 'deep';
  if (value >= 3.5) return 'medium_high';
  if (value >= 3.0) return 'medium';
  if (value >= 2.5) return 'medium_low';
  if (value >= 2.0) return 'shallow';
  return 'very_shallow';
}

String replayabilityLabel(double value) {
  if (value >= 4.5) return 'very_high';
  if (value >= 4.0) return 'high';
  if (value >= 3.5) return 'medium_high';
  if (value >= 3.0) return 'medium';
  if (value >= 2.0) return 'low';
  return 'very_low';
}

List<double> _decisionWeights(int length) {
  if (length == 1) {
    return const [1.0];
  }
  if (length == 2) {
    return const [0.65, 0.35];
  }
  if (length == 3) {
    return const [0.55, 0.30, 0.15];
  }
  return [
    for (var i = 0; i < length; i += 1)
      if (i == 0)
        0.5
      else if (i == 1)
        0.25
      else
        math.max(0.5 / math.max(1, length - 2), 0.25 / (length - 2)),
  ];
}

List<double> _interactionWeights(int length) {
  if (length == 1) {
    return const [1.0];
  }
  if (length == 2) {
    return const [0.65, 0.35];
  }
  if (length == 3) {
    return const [0.55, 0.30, 0.15];
  }
  final topN = math.min(3, length);
  return [
    for (var i = 0; i < length; i += 1)
      if (i == 0)
        0.3
      else if (i == 1)
        0.2
      else if (i == 2)
        0.15
      else
        0.35 / (length - topN),
  ];
}

double _weighted(List<double> values, List<double> weights) {
  final sum = weights.fold<double>(0, (total, value) => total + value);
  if (sum == 0) {
    return 0;
  }
  var result = 0.0;
  for (var i = 0; i < values.length; i += 1) {
    result += values[i] * (weights[i] / sum);
  }
  return result;
}

int? _rankValue(GameRanks ranks, [String type = 'boardgame']) {
  for (final rank in ranks.values) {
    if (rank.type == type) {
      return int.tryParse(rank.rank);
    }
  }
  return null;
}

int? _yearPublished(Game game) {
  return int.tryParse(game.yearPublished ?? '');
}

String _learningCurveType(double initialBarrier, double strategicDepth) {
  if (initialBarrier > 4.3) {
    if (strategicDepth > 4.3) return 'steep';
    if (strategicDepth > 3.5) return 'steep_then_moderate';
    return 'steep_then_shallow';
  }
  if (initialBarrier > 3.5) {
    if (strategicDepth > 4.3) return 'moderate_then_deep';
    if (strategicDepth > 3.5) return 'moderate';
    return 'moderate_then_shallow';
  }
  if (strategicDepth > 4.3) return 'gentle_then_deep';
  if (strategicDepth > 3.5) return 'gentle_then_moderate';
  return 'gentle';
}

List<String> _playerTypes({
  required Game game,
  required double initialBarrier,
  required double strategicDepth,
  required double replayability,
}) {
  final types = <String>[];
  if (initialBarrier < 3.0 && strategicDepth < 3.5) types.add('beginner');
  if (initialBarrier < 4.0 && strategicDepth < 4.5) types.add('casual');
  if (strategicDepth >= 3.0) types.add('experienced');
  if (initialBarrier > 3.0 && strategicDepth > 3.5) types.add('hardcore');
  if (strategicDepth > 3.8) types.add('strategist');
  if (game.mechanics.length >= 5 && strategicDepth > 3.5) {
    types.add('system_master');
  }
  if (replayability >= 3.8) types.add('replayer');
  final rank = _rankValue(game.ranks);
  if (rank != null && rank <= 1000) types.add('trend_follower');
  final year = _yearPublished(game);
  if (year != null && year <= 2000) types.add('classic_lover');
  if (types.isEmpty) {
    if (strategicDepth >= 3.5) {
      types.add('experienced');
    } else if (initialBarrier >= 3.5) {
      types.add('hardcore');
    } else {
      types.add('casual');
    }
  }
  return types;
}

String _masteryTime({
  required double initialBarrier,
  required double strategicDepth,
  required int mechanicCount,
}) {
  if (strategicDepth > 4.3) {
    return mechanicCount >= 6 ? 'long' : 'medium_to_long';
  }
  if (strategicDepth > 3.5) {
    return initialBarrier > 4.0 ? 'medium_to_long' : 'medium';
  }
  return initialBarrier > 4.0 ? 'medium' : 'short';
}

class _StrategicDepth {
  const _StrategicDepth({
    required this.strategicDepth,
    required this.decisionPoints,
    required this.interactionComplexity,
    required this.rulesComplexity,
  });

  final double strategicDepth;
  final double decisionPoints;
  final double interactionComplexity;
  final double rulesComplexity;
}

class _PlaytimeAnalysis {
  const _PlaytimeAnalysis({
    this.strategicBonus = 0.0,
    this.interactionModifier = 0.0,
    this.decisionDensity = 0.0,
    this.complexityFactor = 1.0,
  });

  final double strategicBonus;
  final double interactionModifier;
  final double decisionDensity;
  final double complexityFactor;
}
