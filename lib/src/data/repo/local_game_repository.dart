import '../db/app_database.dart';
import '../../domain/game_names.dart';

class LocalGameRepository {
  LocalGameRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<LocalGameRegistrationResult> register({
    required String title,
    int? publisherMinPlayers,
    int? publisherMaxPlayers,
    int? playingTime,
    List<String> mechanics = const [],
    List<String> categories = const [],
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw const InvalidLocalGameException('Title is required');
    }

    final gameKey = await _database.insertLocalGame(
      title: normalizedTitle,
      names: GameNames(primary: normalizedTitle, japanese: normalizedTitle),
      publisherMinPlayers: publisherMinPlayers,
      publisherMaxPlayers: publisherMaxPlayers,
      playingTime: playingTime,
      mechanics: mechanics,
      categories: categories,
    );

    await _database.upsertCollection(
      CollectionEntriesCompanion.insert(gameKey: gameKey),
    );

    final game = await _database.findGame(gameKey);
    if (game == null) {
      throw StateError('Registered local game was not found: $gameKey');
    }

    return LocalGameRegistrationResult(game: game, isLocal: true);
  }
}

class LocalGameRegistrationResult {
  const LocalGameRegistrationResult({
    required this.game,
    required this.isLocal,
  });

  final Game game;
  final bool isLocal;
}

class InvalidLocalGameException implements Exception {
  const InvalidLocalGameException(this.message);

  final String message;

  @override
  String toString() => 'InvalidLocalGameException: $message';
}
