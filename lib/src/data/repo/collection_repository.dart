import 'package:drift/drift.dart' show Value;

import '../../core/constants.dart';
import '../../domain/community_players.dart';
import '../../domain/display_names.dart';
import '../../domain/play_audience.dart';
import '../db/app_database.dart';
import 'play_session_repository.dart';

class CollectionRepository {
  CollectionRepository({
    required AppDatabase database,
    required PlaySessionRepository playSessions,
  }) : _database = database,
       _playSessions = playSessions;

  final AppDatabase _database;
  final PlaySessionRepository _playSessions;

  Future<List<CollectionListItem>> list({
    CollectionFilter filter = const CollectionFilter(),
    CollectionSortOrder sortOrder = CollectionSortOrder.name,
    String displayLocaleCode = 'ja',
    String fallbackDisplayName = 'Unknown title',
  }) async {
    final games = await _database.select(_database.games).get();
    final collectionRows = await _database
        .select(_database.collectionEntries)
        .get();
    final collectionByKey = {
      for (final collection in collectionRows) collection.gameKey: collection,
    };
    final allSessions = await _playSessions.listAll();
    final sessionsByGameKey = <String, List<PlaySessionRecord>>{};
    for (final session in allSessions) {
      sessionsByGameKey.putIfAbsent(session.gameKey, () => []).add(session);
    }
    final parentKeysWithExpansions = {
      for (final game in games)
        if (game.gameKind == AppConstants.gameKindExpansion &&
            game.parentGameKey != null)
          game.parentGameKey!,
    };
    final items = <CollectionListItem>[];

    for (final game in games) {
      final collection = collectionByKey[game.gameKey];
      if (collection == null) {
        continue;
      }
      final sessionRecords = game.gameKind == AppConstants.gameKindExpansion
          ? const <PlaySessionRecord>[]
          : (sessionsByGameKey[game.gameKey] ?? const <PlaySessionRecord>[]);
      final item = CollectionListItem(
        game: game,
        collection: collection,
        displayName: resolveDisplayName(
          game,
          displayLocaleCode,
          fallback: fallbackDisplayName,
        ),
        subtitle: resolveSubtitle(game, displayLocaleCode),
        bestPlayersBadge: resolveBestPlayersBadge(game.suggestedPlayerVotes),
        isLocal: game.localId != null,
        playCount: sessionRecords.length,
        lastPlayedDate: sessionRecords.isEmpty
            ? null
            : sessionRecords.first.playedDate,
      );
      if (_matches(item, filter, parentKeysWithExpansions)) {
        items.add(item);
      }
    }

    items.sort((a, b) {
      final primaryCompare = switch (sortOrder) {
        CollectionSortOrder.name => 0,
        CollectionSortOrder.designer => _designerSortKey(
          a,
        ).compareTo(_designerSortKey(b)),
        CollectionSortOrder.lastPlayed => (a.lastPlayedDate ?? '').compareTo(
          b.lastPlayedDate ?? '',
        ),
      };
      if (primaryCompare != 0) {
        return primaryCompare;
      }
      return a.displayName.compareTo(b.displayName);
    });
    return items;
  }

  Future<CollectionFacets> facets() async {
    final games = await _database.select(_database.games).get();
    final collectionRows = await _database
        .select(_database.collectionEntries)
        .get();
    final collectionByKey = {
      for (final collection in collectionRows) collection.gameKey: collection,
    };
    final mechanics = <String>{};
    final designers = <String>{};
    for (final game in games) {
      final collection = collectionByKey[game.gameKey];
      if (collection == null) {
        continue;
      }
      mechanics.addAll(
        game.mechanics
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      );
      designers.addAll(
        game.designers
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      );
    }
    return CollectionFacets(
      mechanics: mechanics.toList()..sort(),
      designers: designers.toList()..sort(),
    );
  }

  Future<void> updateMetadata({
    required String gameKey,
    bool? owned,
    String? acquiredDate,
    String? condition,
    String? storageLocation,
    String? memo,
    double? purchasePrice,
  }) async {
    final existing = await _database.findCollection(gameKey);
    await _database.upsertCollection(
      CollectionEntriesCompanion.insert(
        gameKey: gameKey,
        owned: Value(owned ?? existing?.owned ?? true),
        acquiredDate: Value(acquiredDate ?? existing?.acquiredDate),
        condition: Value(condition ?? existing?.condition),
        storageLocation: Value(storageLocation ?? existing?.storageLocation),
        memo: Value(memo ?? existing?.memo),
        purchasePrice: Value(purchasePrice ?? existing?.purchasePrice),
      ),
    );
  }

  Future<DeleteRequirement> deleteRequirement(String gameKey) async {
    final playSessions = await (_database.select(
      _database.playSessions,
    )..where((session) => session.gameKey.equals(gameKey))).get();
    if (playSessions.isNotEmpty) {
      return DeleteRequirement.confirmationRequired;
    }

    final collection = await _database.findCollection(gameKey);
    if (collection == null || !_hasUserMetadata(collection)) {
      return DeleteRequirement.noConfirmation;
    }
    return DeleteRequirement.confirmationRequired;
  }

  Future<void> deleteGame(String gameKey, {bool confirmed = false}) async {
    final requirement = await deleteRequirement(gameKey);
    if (requirement == DeleteRequirement.confirmationRequired && !confirmed) {
      throw const DeleteConfirmationRequiredException();
    }

    await _database.transaction(() async {
      await (_database.delete(
        _database.playSessionExpansions,
      )..where((expansion) => expansion.expansionGameKey.equals(gameKey))).go();

      final game = await _database.findGame(gameKey);
      if (game == null || game.gameKind != AppConstants.gameKindExpansion) {
        final sessions = await (_database.select(
          _database.playSessions,
        )..where((session) => session.gameKey.equals(gameKey))).get();
        for (final session in sessions) {
          await (_database.delete(_database.playSessionExpansions)..where(
                (expansion) => expansion.playSessionId.equals(session.id),
              ))
              .go();
        }
        await (_database.delete(
          _database.playSessions,
        )..where((session) => session.gameKey.equals(gameKey))).go();
      }

      await (_database.delete(
        _database.collectionEntries,
      )..where((entry) => entry.gameKey.equals(gameKey))).go();
      await (_database.delete(
        _database.games,
      )..where((game) => game.gameKey.equals(gameKey))).go();
    });
  }

  bool _matches(
    CollectionListItem item,
    CollectionFilter filter,
    Set<String> parentKeysWithExpansions,
  ) {
    if (filter.localOnly && !item.isLocal) {
      return false;
    }
    if (filter.titleQuery != null && filter.titleQuery!.trim().isNotEmpty) {
      final query = filter.titleQuery!.trim().toLowerCase();
      final candidates = [
        item.game.name,
        item.game.japaneseName,
        item.game.names.primary,
        item.game.names.japanese,
        item.game.names.english,
        ...item.game.names.alternates,
      ].whereType<String>().map((value) => value.toLowerCase());
      if (!candidates.any((value) => value.contains(query))) {
        return false;
      }
    }
    if (filter.playerCount != null) {
      final min = item.game.publisherMinPlayers;
      final max = item.game.publisherMaxPlayers;
      if (min == null || max == null) {
        return false;
      }
      if (filter.playerCount! < min || filter.playerCount! > max) {
        return false;
      }
    }
    if (filter.maxPlayingTime != null) {
      final playingTime = item.game.playingTime;
      if (playingTime == null || playingTime > filter.maxPlayingTime!) {
        return false;
      }
    }
    if (filter.mechanics.isNotEmpty &&
        !_containsAny(item.game.mechanics, filter.mechanics)) {
      return false;
    }
    if (filter.designers.isNotEmpty &&
        !_containsAny(item.game.designers, filter.designers)) {
      return false;
    }
    if (filter.hasExpansionsOnly &&
        !parentKeysWithExpansions.contains(item.game.gameKey)) {
      return false;
    }
    if (filter.unplayedOnly && item.playCount != 0) {
      return false;
    }
    if (filter.playAudience != null &&
        classifyPlayAudience(item.game.weight) != filter.playAudience) {
      return false;
    }
    return true;
  }
}

enum CollectionSortOrder { name, designer, lastPlayed }

class CollectionFilter {
  const CollectionFilter({
    this.titleQuery,
    this.playerCount,
    this.maxPlayingTime,
    this.localOnly = false,
    this.mechanics = const [],
    this.designers = const [],
    this.hasExpansionsOnly = false,
    this.unplayedOnly = false,
    this.playAudience,
  });

  final String? titleQuery;
  final int? playerCount;
  final int? maxPlayingTime;
  final bool localOnly;
  final List<String> mechanics;
  final List<String> designers;
  final bool hasExpansionsOnly;
  final bool unplayedOnly;
  final PlayAudience? playAudience;
}

class CollectionListItem {
  const CollectionListItem({
    required this.game,
    required this.collection,
    required this.displayName,
    required this.subtitle,
    required this.bestPlayersBadge,
    required this.isLocal,
    this.playCount = 0,
    this.lastPlayedDate,
  });

  final Game game;
  final CollectionEntry collection;
  final String displayName;
  final String? subtitle;
  final String? bestPlayersBadge;

  /// Local-only records are games created in-app with a non-null localId,
  /// meaning they are not registered through BGG (including indie/custom games).
  final bool isLocal;
  final int playCount;
  final String? lastPlayedDate;
}

class CollectionFacets {
  const CollectionFacets({
    this.mechanics = const [],
    this.designers = const [],
  });

  final List<String> mechanics;
  final List<String> designers;
}

String _designerSortKey(CollectionListItem item) {
  final designers = item.game.designers;
  return designers.isEmpty ? '\uffff' : designers.first;
}

class CollectionGroup {
  const CollectionGroup({
    required this.parent,
    this.expansions = const [],
    this.isOrphanExpansion = false,
  });

  final CollectionListItem parent;
  final List<CollectionListItem> expansions;
  final bool isOrphanExpansion;
}

List<CollectionGroup> groupCollectionItems(List<CollectionListItem> items) {
  final byKey = {for (final item in items) item.game.gameKey: item};
  final childrenByParent = <String, List<CollectionListItem>>{};
  final groupedChildKeys = <String>{};

  for (final item in items) {
    final parentKey = item.game.parentGameKey;
    if (item.game.gameKind == AppConstants.gameKindExpansion &&
        parentKey != null &&
        byKey.containsKey(parentKey)) {
      childrenByParent.putIfAbsent(parentKey, () => []).add(item);
      groupedChildKeys.add(item.game.gameKey);
    }
  }

  final groups = <CollectionGroup>[];
  for (final item in items) {
    if (groupedChildKeys.contains(item.game.gameKey)) {
      continue;
    }
    final expansions = childrenByParent[item.game.gameKey] ?? const [];
    final sortedExpansions = [...expansions]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    groups.add(
      CollectionGroup(
        parent: item,
        expansions: sortedExpansions,
        isOrphanExpansion: item.game.gameKind == AppConstants.gameKindExpansion,
      ),
    );
  }
  return groups;
}

enum DeleteRequirement { noConfirmation, confirmationRequired }

class DeleteConfirmationRequiredException implements Exception {
  const DeleteConfirmationRequiredException();

  @override
  String toString() => 'DeleteConfirmationRequiredException';
}

String? resolveBestPlayersBadge(SuggestedPlayerVotes votes) {
  final adopted = <SuggestedPlayerVote>[];
  for (final vote in votes.values) {
    if (vote.total < AppConstants.recommendedPlayersMinimumVotes) {
      continue;
    }
    if (vote.best > vote.total * AppConstants.bestPlayerVoteThreshold) {
      adopted.add(vote);
      continue;
    }
    if ((vote.best + vote.recommended) >
        vote.total * AppConstants.recommendedPlayerVoteThreshold) {
      adopted.add(vote);
    }
  }

  if (adopted.isEmpty) {
    return null;
  }

  adopted.sort((a, b) => a.sortValue.compareTo(b.sortValue));
  if (adopted.length == 1) {
    return '${adopted.single.label}人';
  }
  return '${adopted.first.label}–${adopted.last.label}人';
}

bool _hasUserMetadata(CollectionEntry collection) {
  return (collection.acquiredDate?.isNotEmpty ?? false) ||
      (collection.condition?.isNotEmpty ?? false) ||
      (collection.storageLocation?.isNotEmpty ?? false) ||
      (collection.memo?.isNotEmpty ?? false) ||
      collection.purchasePrice != null;
}

bool _containsAny(List<String> values, List<String> selected) {
  final normalized = values.map((value) => value.trim()).toSet();
  return selected.any((value) => normalized.contains(value.trim()));
}
