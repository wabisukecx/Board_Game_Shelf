import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/domain/complexity_tables.dart';
import 'package:bg_shelf_scanner/src/domain/game_rank.dart';

void main() {
  test('loads YAML values and returns configured or fallback entries', () {
    final tables = _tables();

    expect(tables.mechanic('Action Points').complexity, 3.1);
    expect(tables.mechanic('Action Points').strategicValue, 4.0);
    expect(tables.mechanic('Unknown').complexity, 2.5);
    expect(tables.mechanic('Unknown').strategicValue, 3.0);
    expect(tables.category('Strategy').complexity, 4.0);
    expect(tables.category('Unknown').complexity, 2.5);
    expect(tables.rankTypeComplexity('strategygames'), 4.2);
    expect(tables.rankTypeComplexity('unknown'), 3.0);
  });

  test('category complexity applies average and count factor', () {
    final tables = _tables();

    expect(tables.calculateCategoryComplexity(['Strategy']), 4.0);
    expect(
      tables.calculateCategoryComplexity(['Strategy', 'Family']),
      closeTo(3.15, 0.001),
    );
    expect(tables.calculateCategoryComplexity([]), 2.5);
  });

  test('rank position score follows analyzer thresholds', () {
    final tables = _tables();

    expect(tables.calculateRankPositionScore(1), 5.0);
    expect(tables.calculateRankPositionScore(100), 4.0);
    expect(tables.calculateRankPositionScore(1000), 3.0);
    expect(tables.calculateRankPositionScore(5000), 2.0);
    expect(tables.calculateRankPositionScore('Not Ranked'), 2.5);
  });

  test('rank complexity combines rank type and popularity', () {
    final tables = _tables();

    final score = tables.calculateRankComplexity(
      const GameRanks([
        GameRank(type: 'strategygames', rank: '10'),
        GameRank(type: 'familygames', rank: '1000'),
      ]),
    );

    expect(score, closeTo(2.992, 0.001));
    expect(tables.calculateRankComplexity(const GameRanks([])), 3.0);
  });
}

ComplexityTables _tables() {
  return ComplexityTables.fromYamlStrings(
    mechanicsYaml: '''
Action Points:
  complexity: 3.1
  strategic_value: 4.0
  interaction_value: 2.5
Dice Rolling:
  complexity: 1.8
  strategic_value: 2.0
  interaction_value: 3.0
''',
    categoriesYaml: '''
Strategy:
  complexity: 4.0
  strategic_value: 4.5
  interaction_value: 3.0
Family:
  complexity: 2.0
  strategic_value: 2.5
  interaction_value: 3.5
''',
    rankTypesYaml: '''
boardgame:
  complexity: 3.0
strategygames:
  complexity: 4.2
familygames:
  complexity: 2.3
''',
  );
}
