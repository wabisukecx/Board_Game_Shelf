import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';

void main() {
  const parser = BggXmlParser();

  test(
    'parses inbound boardgameexpansion links as this game\'s own expansions',
    () {
      final details = parser.parseThing('''
<items>
  <item type="boardgame" id="13">
    <name type="primary" value="CATAN" />
    <link type="boardgameexpansion" id="111" value="Seafarers" inbound="true" />
    <link type="boardgameexpansion" id="222" value="Cities &amp; Knights" inbound="true" />
  </item>
</items>
''');

      expect(details.expandsGame, isNull);
      expect(details.itemType, 'boardgame');
      expect(details.expansionLinks, hasLength(2));
      expect(details.expansionLinks.first.bggId, '111');
      expect(details.expansionLinks.first.name, 'Seafarers');
    },
  );

  test(
    'parses non-inbound boardgameexpansion link as the "Expansion for" parent game',
    () {
      final details = parser.parseThing('''
<items>
  <item type="boardgameexpansion" id="111">
    <name type="primary" value="Seafarers" />
    <link type="boardgameexpansion" id="13" value="CATAN" />
    <link type="boardgameexpansion" id="999" value="Ignored second parent" />
  </item>
</items>
''');

      expect(details.expansionLinks, isEmpty);
      expect(details.expandsGame?.bggId, '13');
      expect(details.expandsGame?.name, 'CATAN');
    },
  );

  test(
    'inbound link on an expansion item is its own (sub-)expansion, not its parent',
    () {
      final details = parser.parseThing('''
<items>
  <item type="boardgameexpansion" id="151022">
    <name type="primary" value="Pandemic: On the Brink" />
    <link type="boardgameexpansion" id="30549" value="Pandemic" />
    <link type="boardgameexpansion" id="999999" value="On the Brink: Mini Expansion" inbound="true" />
  </item>
</items>
''');

      expect(details.itemType, 'boardgameexpansion');
      // The parent ("Expansion for: Pandemic") comes from the non-inbound
      // link, not from this expansion's own inbound expansion link.
      expect(details.expandsGame?.bggId, '30549');
      expect(details.expandsGame?.name, 'Pandemic');
      expect(details.expansionLinks, hasLength(1));
      expect(details.expansionLinks.first.bggId, '999999');
      expect(details.expansionLinks.first.name, 'On the Brink: Mini Expansion');
    },
  );

  test('inbound false is treated the same as no inbound attribute', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgameexpansion" id="111">
    <name type="primary" value="Seafarers" />
    <link type="boardgameexpansion" id="13" value="CATAN" inbound="false" />
  </item>
</items>
''');

    expect(details.expansionLinks, isEmpty);
    expect(details.expandsGame?.bggId, '13');
  });

  test(
    'parses item type separately from a non-inbound expansion relationship',
    () {
      final details = parser.parseThing('''
<items>
  <item type="boardgame" id="41002">
    <name type="primary" value="Architects of the West Kingdom" />
    <link type="boardgameexpansion" id="41003" value="German edition" />
  </item>
</items>
''');

      expect(details.itemType, 'boardgame');
      expect(details.expandsGame, isNull);
      expect(details.expansionLinks, isEmpty);
    },
  );

  test('keeps all expansion relationship links for repository resolution', () {
    final details = parser.parseThing('''
<items>
  <item type="boardgameexpansion" id="455953">
    <name type="primary" value="Nucleum: Gibraltar" />
    <link type="boardgameexpansion" id="468319" value="Nucleum: New Military Technologies Promo" />
    <link type="boardgameexpansion" id="396790" value="Nucleum" inbound="true" />
  </item>
</items>
''');

    expect(details.expansionRelationshipLinks.map((link) => link.bggId), [
      '468319',
      '396790',
    ]);
  });
}
