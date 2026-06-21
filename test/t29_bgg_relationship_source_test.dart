import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/bgg/bgg_relationship_source.dart';

void main() {
  test('uses boardgameexpansion links for a base game', () {
    final candidates = parseBggRegistrationCandidates('''
{
  "item": {
    "subtype": "boardgame",
    "links": {
      "boardgameexpansion": [
        {"name": "Seafarers", "objectid": "111"}
      ],
      "expandsboardgame": []
    }
  }
}
''');

    expect(candidates.single.name, 'Seafarers');
    expect(candidates.single.bggId, '111');
  });

  test('uses expandsboardgame links for an expansion item', () {
    final candidates = parseBggRegistrationCandidates('''
{
  "item": {
    "subtype": "boardgameexpansion",
    "links": {
      "boardgameexpansion": [],
      "expandsboardgame": [
        {"name": "Dominion", "objectid": "36218"},
        {"name": "Dominion: Second Edition", "objectid": "209418"}
      ]
    }
  }
}
''');

    expect(candidates.map((candidate) => candidate.bggId), ['36218', '209418']);
  });
}
