import '../data/db/app_database.dart';

String resolveDisplayName(
  Game game,
  String localeCode, {
  required String fallback,
}) {
  return _firstNonEmpty(_displayNameCandidates(game, localeCode)) ?? fallback;
}

String? resolveSubtitle(Game game, String localeCode) {
  final displayName = resolveDisplayName(game, localeCode, fallback: '');
  final alternate = _firstNonEmpty(_subtitleCandidates(game, localeCode));
  if (alternate == null || alternate == displayName) {
    return null;
  }
  return alternate;
}

Iterable<String?> _displayNameCandidates(Game game, String localeCode) sync* {
  if (_isJapanese(localeCode)) {
    yield game.names.japanese;
    yield game.japaneseName;
    yield game.names.primary;
    yield game.names.english;
    yield game.name;
    return;
  }

  yield game.names.english;
  yield game.names.primary;
  yield game.names.japanese;
  yield game.japaneseName;
  yield game.name;
}

Iterable<String?> _subtitleCandidates(Game game, String localeCode) sync* {
  if (_isJapanese(localeCode)) {
    yield game.names.english;
    yield game.names.primary;
    return;
  }

  yield game.names.japanese;
  yield game.japaneseName;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

bool _isJapanese(String localeCode) {
  return localeCode.toLowerCase().split(RegExp('[-_]')).first == 'ja';
}
