import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../core/constants.dart';
import 'game_rank.dart';

class ComplexityEntry {
  const ComplexityEntry({
    required this.complexity,
    required this.strategicValue,
    required this.interactionValue,
  });

  final double complexity;
  final double strategicValue;
  final double interactionValue;
}

class ComplexityTables {
  const ComplexityTables({
    required this.mechanics,
    required this.categories,
    required this.rankTypes,
  });

  factory ComplexityTables.fromYamlStrings({
    required String mechanicsYaml,
    required String categoriesYaml,
    required String rankTypesYaml,
  }) {
    return ComplexityTables(
      mechanics: _parseEntries(mechanicsYaml),
      categories: _parseEntries(categoriesYaml),
      rankTypes: _parseEntries(rankTypesYaml),
    );
  }

  static Future<ComplexityTables> load({AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    final mechanicsYaml = await assetBundle.loadString(
      AppConstants.mechanicsAnalysisAsset,
    );
    final categoriesYaml = await assetBundle.loadString(
      AppConstants.categoriesAnalysisAsset,
    );
    final rankTypesYaml = await assetBundle.loadString(
      AppConstants.rankComplexityAnalysisAsset,
    );
    return ComplexityTables.fromYamlStrings(
      mechanicsYaml: mechanicsYaml,
      categoriesYaml: categoriesYaml,
      rankTypesYaml: rankTypesYaml,
    );
  }

  final Map<String, ComplexityEntry> mechanics;
  final Map<String, ComplexityEntry> categories;
  final Map<String, ComplexityEntry> rankTypes;

  ComplexityEntry mechanic(String name) {
    return mechanics[name] ??
        const ComplexityEntry(
          complexity: AppConstants.fallbackMechanicComplexity,
          strategicValue: AppConstants.fallbackMechanicStrategicValue,
          interactionValue: AppConstants.fallbackMechanicInteractionValue,
        );
  }

  ComplexityEntry category(String name) {
    return categories[name] ??
        const ComplexityEntry(
          complexity: AppConstants.fallbackCategoryComplexity,
          strategicValue: AppConstants.fallbackMechanicStrategicValue,
          interactionValue: AppConstants.fallbackMechanicInteractionValue,
        );
  }

  double rankTypeComplexity(String type) {
    return rankTypes[type]?.complexity ??
        AppConstants.fallbackRankTypeComplexity;
  }

  double calculateCategoryComplexity(List<String> categoryNames) {
    if (categoryNames.isEmpty) {
      return AppConstants.fallbackCategoryComplexity;
    }
    final average =
        categoryNames
            .map((name) => category(name).complexity)
            .fold<double>(0, (sum, value) => sum + value) /
        categoryNames.length;
    final countFactor = math.min(1.3, 1.0 + (categoryNames.length - 1) * 0.05);
    return clampScore(average * countFactor);
  }

  double calculateRankPositionScore(Object? rankValue) {
    final rank = switch (rankValue) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };
    if (rank == null) {
      return 2.5;
    }
    if (rank <= 10) {
      return 5.0;
    }
    if (rank <= 100) {
      return 4.5 - (rank - 10) / 90 * 0.5;
    }
    if (rank <= 1000) {
      return 4.0 - (rank - 100) / 900 * 1.0;
    }
    if (rank <= 5000) {
      return 3.0 - (rank - 1000) / 4000 * 1.0;
    }
    return math.max(1.0, 2.0 - _log10(rank / 5000));
  }

  double calculateRankComplexity(GameRanks ranks) {
    var totalWeight = 0.0;
    var weightedSum = 0.0;
    for (final rank in ranks.values) {
      if (rank.rank.isEmpty || rank.rank == 'Not Ranked') {
        continue;
      }
      final parsedRank = int.tryParse(rank.rank);
      if (parsedRank == null) {
        continue;
      }
      final popularityScore = calculateRankPositionScore(parsedRank);
      final typeComplexity = rankTypeComplexity(
        rank.type.isEmpty ? 'boardgame' : rank.type,
      );
      final adjustedScore =
          typeComplexity * 0.8 + (popularityScore - 3.0) * 0.2;
      final weight = switch (rank.type) {
        'strategygames' || 'wargames' => 1.2,
        'familygames' || 'partygames' || 'childrensgames' => 0.8,
        _ => 1.0,
      };
      weightedSum += adjustedScore * weight;
      totalWeight += weight;
    }
    if (totalWeight == 0) {
      return AppConstants.fallbackRankTypeComplexity;
    }
    return clampScore(weightedSum / totalWeight);
  }
}

double clampScore(double value) {
  return value.clamp(
    AppConstants.analysisMinScore,
    AppConstants.analysisMaxScore,
  );
}

double roundScore(double value) => (value * 100).round() / 100;

Map<String, ComplexityEntry> _parseEntries(String source) {
  final yaml = loadYaml(source);
  if (yaml is! YamlMap) {
    return const {};
  }
  final entries = <String, ComplexityEntry>{};
  for (final entry in yaml.entries) {
    final key = entry.key;
    if (key is! String) {
      continue;
    }
    final value = entry.value;
    if (value is num) {
      final complexity = value.toDouble();
      entries[key] = ComplexityEntry(
        complexity: complexity,
        strategicValue: clampScore(complexity * 0.9),
        interactionValue: AppConstants.fallbackMechanicInteractionValue,
      );
    } else if (value is YamlMap) {
      final complexity =
          _numberAt(value, 'complexity') ??
          AppConstants.fallbackMechanicComplexity;
      entries[key] = ComplexityEntry(
        complexity: complexity,
        strategicValue:
            _numberAt(value, 'strategic_value') ?? clampScore(complexity * 0.9),
        interactionValue:
            _numberAt(value, 'interaction_value') ??
            AppConstants.fallbackMechanicInteractionValue,
      );
    }
  }
  return entries;
}

double? _numberAt(YamlMap map, String key) {
  final value = map[key];
  return value is num ? value.toDouble() : null;
}

double _log10(num value) => math.log(value) / math.ln10;
