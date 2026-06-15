import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../db/app_database.dart';
import '../settings/secure_settings_repository.dart';

abstract interface class TranslationClient {
  Future<String> translate({
    required String apiKey,
    required String prompt,
    required String text,
  });
}

class GeminiTranslationClient implements TranslationClient {
  GeminiTranslationClient({
    Dio? dio,
    this.model = 'gemini-3.5-flash',
    this.endpointBase = 'https://generativelanguage.googleapis.com/v1beta',
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String model;
  final String endpointBase;

  @override
  Future<String> translate({
    required String apiKey,
    required String prompt,
    required String text,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '$endpointBase/models/$model:generateContent',
      options: Options(headers: {'x-goog-api-key': apiKey}),
      data: {
        'contents': [
          {
            'parts': [
              {'text': '$prompt\n\n$text'},
            ],
          },
        ],
      },
    );
    final candidates = response.data?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const TranslationException('Gemini response has no candidates');
    }
    final content = (candidates.first as Map?)?['content'];
    final parts = (content as Map?)?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const TranslationException('Gemini response has no parts');
    }
    final translated = (parts.first as Map?)?['text'];
    if (translated is! String || translated.trim().isEmpty) {
      throw const TranslationException('Gemini response text is empty');
    }
    return translated.trim();
  }
}

class DescriptionTranslationRepository {
  DescriptionTranslationRepository({
    required AppDatabase database,
    required SecureSettingsRepository settings,
    required TranslationClient client,
  }) : _database = database,
       _settings = settings,
       _client = client;

  static const String prompt =
      '次のボードゲーム説明文を自然な日本語に翻訳してください。'
      '出力は翻訳文のみとし、前置きや補足説明は一切含めないでください。';

  final AppDatabase _database;
  final SecureSettingsRepository _settings;
  final TranslationClient _client;

  Future<DescriptionTranslationResult> translateIfNeeded(String gameKey) async {
    final game = await _database.findGame(gameKey);
    if (game == null) {
      throw TranslationException('Game not found: $gameKey');
    }
    final source = game.description;
    if (source == null || source.trim().isEmpty) {
      return DescriptionTranslationResult(
        gameKey: gameKey,
        source: source,
        descriptionJa: game.descriptionJa,
        status: DescriptionTranslationStatus.noSource,
      );
    }
    if (_japaneseRatio(source) > AppConstants.japaneseTranslationSkipRatio) {
      return DescriptionTranslationResult(
        gameKey: gameKey,
        source: source,
        descriptionJa: game.descriptionJa,
        status: DescriptionTranslationStatus.skippedJapaneseText,
      );
    }
    final apiKey = await _settings.readGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return DescriptionTranslationResult(
        gameKey: gameKey,
        source: source,
        descriptionJa: game.descriptionJa,
        status: DescriptionTranslationStatus.missingApiKey,
      );
    }

    try {
      final translated = await _client.translate(
        apiKey: apiKey,
        prompt: prompt,
        text: source,
      );
      await _database.updateDescriptionJa(gameKey, translated);
      return DescriptionTranslationResult(
        gameKey: gameKey,
        source: source,
        descriptionJa: translated,
        status: DescriptionTranslationStatus.translated,
      );
    } catch (_) {
      return DescriptionTranslationResult(
        gameKey: gameKey,
        source: source,
        descriptionJa: game.descriptionJa,
        status: DescriptionTranslationStatus.failed,
      );
    }
  }

  double _japaneseRatio(String text) {
    var japanese = 0;
    var total = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (char.trim().isEmpty) {
        continue;
      }
      total += 1;
      if (_isJapaneseRune(rune)) {
        japanese += 1;
      }
    }
    if (total == 0) {
      return 0;
    }
    return japanese / total;
  }

  bool _isJapaneseRune(int rune) {
    return (rune >= 0x3040 && rune <= 0x9fff) ||
        (rune >= 0xf900 && rune <= 0xfaff);
  }
}

class DescriptionTranslationResult {
  const DescriptionTranslationResult({
    required this.gameKey,
    required this.source,
    required this.descriptionJa,
    required this.status,
  });

  final String gameKey;
  final String? source;
  final String? descriptionJa;
  final DescriptionTranslationStatus status;

  String get displayDescription => descriptionJa ?? source ?? '';
}

enum DescriptionTranslationStatus {
  translated,
  skippedJapaneseText,
  missingApiKey,
  failed,
  noSource,
}

class TranslationException implements Exception {
  const TranslationException(this.message);

  final String message;

  @override
  String toString() => 'TranslationException: $message';
}
