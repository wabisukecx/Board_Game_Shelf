import 'package:xml/xml.dart';

import '../../core/constants.dart';
import '../../domain/community_players.dart';
import '../../domain/game_names.dart';
import '../../domain/game_rank.dart';

class BggXmlParser {
  const BggXmlParser();

  BggGameDetails parseThing(String source) {
    final document = XmlDocument.parse(source);
    final item = document.findAllElements('item').firstOrNull;
    if (item == null) {
      throw const FormatException('BGG thing response has no item');
    }

    final names = _parseNames(item);
    final polls = _parseSuggestedPlayers(item);
    final expansionRelationshipLinks = _expansionRelationshipLinks(item);

    return BggGameDetails(
      bggId: item.getAttribute('id') ?? '',
      itemType: item.getAttribute('type'),
      names: names,
      yearPublished: _valueOf(item, 'yearpublished'),
      thumbnailUrl: item.getElement('thumbnail')?.innerText.trim(),
      publisherMinPlayers: _intValueOf(item, 'minplayers'),
      publisherMaxPlayers: _intValueOf(item, 'maxplayers'),
      playingTime: _intValueOf(item, 'playingtime'),
      publisherMinAge: _intValueOf(item, 'minage'),
      communityBestPlayers: polls.best,
      communityRecommendedPlayers: polls.recommended,
      suggestedPlayerVotes: polls.votes,
      communityMinAge: _parseCommunityMinAge(item),
      description: item.getElement('description')?.innerText.trim(),
      mechanics: _links(item, 'boardgamemechanic'),
      categories: _links(item, 'boardgamecategory'),
      designers: _links(item, 'boardgamedesigner'),
      publishers: _links(item, 'boardgamepublisher'),
      averageRating: _ratingValue(item, 'average'),
      weight: _ratingValue(item, 'averageweight'),
      ranks: _parseRanks(item),
      expansionLinks: _expansionLinks(item),
      expansionRelationshipLinks: expansionRelationshipLinks,
      expandsGame: _expandsGame(item),
    );
  }

  List<BggSearchResult> parseSearch(String source) {
    final document = XmlDocument.parse(source);
    return [
      for (final item in document.findAllElements('item'))
        BggSearchResult(
          bggId: item.getAttribute('id') ?? '',
          name: item.getElement('name')?.getAttribute('value') ?? '',
          yearPublished: item
              .getElement('yearpublished')
              ?.getAttribute('value'),
        ),
    ];
  }

  List<BggCollectionItem> parseCollection(String source) {
    final document = XmlDocument.parse(source);
    return [
      for (final item in document.findAllElements('item'))
        if ((item.getAttribute('objectid') ?? '').trim().isNotEmpty)
          BggCollectionItem(
            objectId: item.getAttribute('objectid')!.trim(),
            name: item.getElement('name')?.innerText.trim() ?? '',
            yearPublished: item.getElement('yearpublished')?.innerText.trim(),
          ),
    ];
  }

  static String normalizeSearchQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), '+');
  }

  GameNames _parseNames(XmlElement item) {
    final nameElements = item.findElements('name').toList();
    final primary = nameElements
        .where((element) => element.getAttribute('type') == 'primary')
        .map((element) => element.getAttribute('value'))
        .whereType<String>()
        .firstOrNull;

    final allNames = [
      for (final element in nameElements)
        if (element.getAttribute('value') case final String value) value,
    ];

    final languageJapanese = nameElements
        .where((element) {
          final language = element.getAttribute('language')?.toLowerCase();
          return language == 'ja' || language == 'jp' || language == 'jpn';
        })
        .map((element) => element.getAttribute('value'))
        .whereType<String>()
        .firstOrNull;

    final heuristicJapanese =
        languageJapanese ??
        nameElements
            .where((element) => element.getAttribute('type') != 'primary')
            .map((element) => element.getAttribute('value'))
            .whereType<String>()
            .where(_hasKana)
            .firstOrNull;

    final primaryName = primary ?? allNames.firstOrNull ?? '';
    return GameNames(
      primary: primaryName,
      japanese: heuristicJapanese,
      english: primaryName,
      alternates: GameNames.dedupeAlternates(
        allNames.where((name) => name != primaryName),
      ),
    );
  }

  _SuggestedPlayers _parseSuggestedPlayers(XmlElement item) {
    final poll = item.findElements('poll').where((poll) {
      return poll.getAttribute('name') == 'suggested_numplayers';
    }).firstOrNull;
    if (poll == null) {
      return const _SuggestedPlayers();
    }

    final best = <String>[];
    final recommended = <String>[];
    final votes = <SuggestedPlayerVote>[];
    for (final results in poll.findElements('results')) {
      final numPlayers = results.getAttribute('numplayers');
      if (numPlayers == null || numPlayers.isEmpty) {
        continue;
      }

      XmlElement? winner;
      var winnerVotes = -1;
      var bestVotes = 0;
      var recommendedVotes = 0;
      var notRecommendedVotes = 0;
      for (final result in results.findElements('result')) {
        final votes = int.tryParse(result.getAttribute('numvotes') ?? '') ?? 0;
        switch (result.getAttribute('value')) {
          case 'Best':
            bestVotes = votes;
          case 'Recommended':
            recommendedVotes = votes;
          case 'Not Recommended':
            notRecommendedVotes = votes;
        }
        if (votes > winnerVotes) {
          winner = result;
          winnerVotes = votes;
        }
      }

      votes.add(
        SuggestedPlayerVote(
          label: numPlayers,
          best: bestVotes,
          recommended: recommendedVotes,
          notRecommended: notRecommendedVotes,
        ),
      );

      switch (winner?.getAttribute('value')) {
        case 'Best':
          best.add(numPlayers);
        case 'Recommended':
          recommended.add(numPlayers);
      }
    }

    return _SuggestedPlayers(
      best: _joinPlayerLabels(best),
      recommended: _joinPlayerLabels(recommended),
      votes: SuggestedPlayerVotes(
        [...votes]..sort((a, b) => a.sortValue.compareTo(b.sortValue)),
      ),
    );
  }

  String? _parseCommunityMinAge(XmlElement item) {
    final poll = item.findElements('poll').where((poll) {
      return poll.getAttribute('name') == 'suggested_playerage';
    }).firstOrNull;
    if (poll == null) {
      return null;
    }

    XmlElement? winner;
    var winnerVotes = -1;
    for (final result in poll.findAllElements('result')) {
      final votes = int.tryParse(result.getAttribute('numvotes') ?? '') ?? 0;
      if (votes > winnerVotes) {
        winner = result;
        winnerVotes = votes;
      }
    }
    return winner?.getAttribute('value');
  }

  List<NamedBggValue> _links(XmlElement item, String type) {
    return [
      for (final link in item.findElements('link'))
        if (link.getAttribute('type') == type)
          NamedBggValue(
            name: link.getAttribute('value') ?? '',
            bggId: link.getAttribute('id'),
          ),
    ];
  }

  /// Links to this item's own expansions (the "Expansions:" section on the
  /// BGG page). On the BGG XML API these are `boardgameexpansion` links
  /// marked `inbound="true"` because the relationship points back into this
  /// item from the expansion item.
  List<NamedBggValue> _expansionLinks(XmlElement item) {
    return [
      for (final link in item.findElements('link'))
        if (link.getAttribute('type') == AppConstants.bggExpansionLinkType &&
            link.getAttribute('inbound')?.toLowerCase() == 'true')
          NamedBggValue(
            name: link.getAttribute('value') ?? '',
            bggId: link.getAttribute('id'),
          ),
    ];
  }

  List<NamedBggValue> _expansionRelationshipLinks(XmlElement item) {
    return [
      for (final link in item.findElements('link'))
        if (link.getAttribute('type') == AppConstants.bggExpansionLinkType)
          NamedBggValue(
            name: link.getAttribute('value') ?? '',
            bggId: link.getAttribute('id'),
          ),
    ];
  }

  /// The base game this item is an expansion for (the "Expansion for:"
  /// section on the BGG page). This is a direction-based fallback only. The
  /// repository resolves ambiguous candidates by fetching their item types.
  NamedBggValue? _expandsGame(XmlElement item) {
    if (item.getAttribute('type') != AppConstants.bggExpansionLinkType) {
      return null;
    }
    return item
        .findElements('link')
        .where((link) {
          if (link.getAttribute('type') != AppConstants.bggExpansionLinkType) {
            return false;
          }
          return link.getAttribute('inbound')?.toLowerCase() != 'true';
        })
        .map(
          (link) => NamedBggValue(
            name: link.getAttribute('value') ?? '',
            bggId: link.getAttribute('id'),
          ),
        )
        .where((value) => value.bggId != null && value.bggId!.isNotEmpty)
        .firstOrNull;
  }

  List<GameRank> _parseRanks(XmlElement item) {
    return [
      for (final rank in item.findAllElements('rank'))
        if (_rankValue(rank) case final String value)
          GameRank(type: rank.getAttribute('name') ?? '', rank: value),
    ];
  }

  String? _rankValue(XmlElement rank) {
    final value = rank.getAttribute('value')?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'not ranked') {
      return null;
    }
    return value;
  }

  String? _ratingValue(XmlElement item, String name) {
    return item.findAllElements(name).firstOrNull?.getAttribute('value');
  }

  String? _valueOf(XmlElement item, String name) {
    return item.getElement(name)?.getAttribute('value');
  }

  int? _intValueOf(XmlElement item, String name) {
    return int.tryParse(_valueOf(item, name) ?? '');
  }

  static bool _hasKana(String value) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(value);
  }

  static String? _joinPlayerLabels(List<String> labels) {
    if (labels.isEmpty) {
      return null;
    }
    final sorted = [...labels]
      ..sort((a, b) {
        final left = int.tryParse(a.replaceAll('+', '')) ?? 0;
        final right = int.tryParse(b.replaceAll('+', '')) ?? 0;
        return left.compareTo(right);
      });
    return sorted.join(', ');
  }
}

class BggGameDetails {
  const BggGameDetails({
    required this.bggId,
    required this.names,
    this.itemType,
    this.yearPublished,
    this.thumbnailUrl,
    this.publisherMinPlayers,
    this.publisherMaxPlayers,
    this.playingTime,
    this.publisherMinAge,
    this.communityBestPlayers,
    this.communityRecommendedPlayers,
    this.suggestedPlayerVotes = const SuggestedPlayerVotes([]),
    this.communityMinAge,
    this.description,
    this.mechanics = const [],
    this.categories = const [],
    this.designers = const [],
    this.publishers = const [],
    this.averageRating,
    this.weight,
    this.ranks = const [],
    this.expansionLinks = const [],
    this.expansionRelationshipLinks = const [],
    this.expandsGame,
  });

  final String bggId;
  final String? itemType;
  final GameNames names;
  final String? yearPublished;
  final String? thumbnailUrl;
  final int? publisherMinPlayers;
  final int? publisherMaxPlayers;
  final int? playingTime;
  final int? publisherMinAge;
  final String? communityBestPlayers;
  final String? communityRecommendedPlayers;
  final SuggestedPlayerVotes suggestedPlayerVotes;
  final String? communityMinAge;
  final String? description;
  final List<NamedBggValue> mechanics;
  final List<NamedBggValue> categories;
  final List<NamedBggValue> designers;
  final List<NamedBggValue> publishers;
  final String? averageRating;
  final String? weight;
  final List<GameRank> ranks;
  final List<NamedBggValue> expansionLinks;
  final List<NamedBggValue> expansionRelationshipLinks;
  final NamedBggValue? expandsGame;
}

class NamedBggValue {
  const NamedBggValue({required this.name, this.bggId});

  final String name;
  final String? bggId;
}

class BggSearchResult {
  const BggSearchResult({
    required this.bggId,
    required this.name,
    this.yearPublished,
  });

  final String bggId;
  final String name;
  final String? yearPublished;
}

class BggCollectionItem {
  const BggCollectionItem({
    required this.objectId,
    required this.name,
    this.yearPublished,
  });

  final String objectId;
  final String name;
  final String? yearPublished;
}

class _SuggestedPlayers {
  const _SuggestedPlayers({
    this.best,
    this.recommended,
    this.votes = const SuggestedPlayerVotes([]),
  });

  final String? best;
  final String? recommended;
  final SuggestedPlayerVotes votes;
}
