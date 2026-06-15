import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';

void main() {
  const parser = BggXmlParser();

  test('uses language attribute first for japanese_name', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgame" id="13">
    <name type="primary" value="CATAN" />
    <name type="alternate" language="ja" value="カタンの開拓者たち" />
  </item>
</items>
''');

    expect(details.names.primary, 'CATAN');
    expect(details.names.japanese, 'カタンの開拓者たち');
  });

  test('uses kana alternate name when language attribute is absent', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgame" id="999">
    <name type="primary" value="Scout" />
    <name type="alternate" value="スカウト" />
  </item>
</items>
''');

    expect(details.names.japanese, 'スカウト');
  });

  test('does not treat kanji-only alternate name as japanese_name', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgame" id="1000">
    <name type="primary" value="Go" />
    <name type="alternate" value="圍棋" />
  </item>
</items>
''');

    expect(details.names.japanese, isNull);
  });

  test('aggregates suggested player poll and sorts labels numerically', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgame" id="1">
    <name type="primary" value="Poll Game" />
    <poll name="suggested_numplayers">
      <results numplayers="4+">
        <result value="Best" numvotes="8" />
        <result value="Recommended" numvotes="7" />
        <result value="Not Recommended" numvotes="0" />
      </results>
      <results numplayers="1">
        <result value="Best" numvotes="0" />
        <result value="Recommended" numvotes="1" />
        <result value="Not Recommended" numvotes="9" />
      </results>
      <results numplayers="2">
        <result value="Best" numvotes="5" />
        <result value="Recommended" numvotes="4" />
        <result value="Not Recommended" numvotes="0" />
      </results>
    </poll>
  </item>
</items>
''');

    expect(details.communityBestPlayers, '2, 4+');
    expect(details.communityRecommendedPlayers, isNull);
  });

  test('parses ranks and excludes Not Ranked', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgame" id="2">
    <name type="primary" value="Ranked Game" />
    <statistics>
      <ratings>
        <average value="7.2" />
        <averageweight value="2.31" />
        <ranks>
          <rank name="boardgame" value="429" />
          <rank name="strategygames" value="Not Ranked" />
        </ranks>
      </ratings>
    </statistics>
  </item>
</items>
''');

    expect(details.averageRating, '7.2');
    expect(details.weight, '2.31');
    expect(details.ranks, hasLength(1));
    expect(details.ranks.single.type, 'boardgame');
    expect(details.ranks.single.rank, '429');
  });

  test('parses XML with missing weight average and ranks without throwing', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgame" id="3">
    <name type="primary" value="Sparse Game" />
  </item>
</items>
''');

    expect(details.averageRating, isNull);
    expect(details.weight, isNull);
    expect(details.ranks, isEmpty);
  });

  test('normalizes search query whitespace to plus signs', () {
    expect(BggXmlParser.normalizeSearchQuery('  Ark  Nova '), 'Ark+Nova');
  });
}
