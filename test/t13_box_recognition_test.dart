import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/repo/box_recognition_repository.dart';
import 'package:bg_shelf_scanner/src/data/settings/secret_store.dart';
import 'package:bg_shelf_scanner/src/data/settings/secure_settings_repository.dart';
import 'package:bg_shelf_scanner/src/data/vision/gemini_vision_service.dart';

void main() {
  test('parses C-27 JSON, sorts by confidence, and limits to five', () {
    final parsed = parseVisionJson('''
{
  "candidates": [
    {"title": "Low", "confidence": 0.1},
    {"title": "High", "japaneseTitle": "ハイ", "publisher": "Pub", "confidence": 0.95},
    {"title": "Mid", "confidence": "0.6"},
    {"title": "A", "confidence": 0.5},
    {"title": "B", "confidence": 0.49},
    {"title": "C", "confidence": 0.48}
  ],
  "note": "single box"
}
''');

    expect(parsed.note, 'single box');
    expect(parsed.candidates, hasLength(AppConstants.visionMaxCandidates));
    expect(parsed.candidates.first.title, 'High');
    expect(parsed.candidates.first.japaneseTitle, 'ハイ');
    expect(parsed.candidates.first.publisher, 'Pub');
  });

  test('builds search query from title and publisher, never BGG id', () {
    const candidate = BoxRecognitionCandidate(
      title: 'Modern Art',
      publisher: 'CMON',
      confidence: 0.8,
    );

    expect(searchQueryForCandidate(candidate), 'Modern Art CMON');
  });

  test('preprocesses image to JPEG with long edge at most 1024', () {
    final source = img.Image(width: 1600, height: 800)
      ..clear(img.ColorRgb8(255, 0, 0));

    final bytes = preprocessBoxImage(img.encodePng(source));
    final decoded = img.decodeImage(Uint8List.fromList(bytes!));

    expect(decoded, isNotNull);
    expect(decoded!.width, AppConstants.visionImageMaxLongEdge);
    expect(decoded.height, 512);
  });

  test(
    'missing Gemini key returns missingApiKey without calling client',
    () async {
      final client = FakeVisionClient();
      final repository = BoxRecognitionRepository(
        settings: SecureSettingsRepository(secretStore: MemorySecretStore()),
        client: client,
      );

      final result = await repository.recognize(_onePixelPng());

      expect(result.status, BoxRecognitionStatus.missingApiKey);
      expect(client.callCount, 0);
    },
  );

  test('low confidence returns lowConfidence', () async {
    final store = MemorySecretStore();
    final settings = SecureSettingsRepository(secretStore: store);
    await settings.saveGeminiApiKey('unit-gemini-key');
    final repository = BoxRecognitionRepository(
      settings: settings,
      client: FakeVisionClient(
        response: '{"candidates":[{"title":"Maybe","confidence":0.2}]}',
      ),
    );

    final result = await repository.recognize(_onePixelPng());

    expect(result.status, BoxRecognitionStatus.lowConfidence);
    expect(result.candidates.single.title, 'Maybe');
  });

  test('network exception returns noNetwork', () async {
    final store = MemorySecretStore();
    final settings = SecureSettingsRepository(secretStore: store);
    await settings.saveGeminiApiKey('unit-gemini-key');
    final repository = BoxRecognitionRepository(
      settings: settings,
      client: FakeVisionClient(
        error: DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
          error: const SocketException('offline'),
        ),
      ),
    );

    final result = await repository.recognize(_onePixelPng());

    expect(result.status, BoxRecognitionStatus.noNetwork);
  });

  test(
    'confident candidates are returned and prompt requests JSON only',
    () async {
      final store = MemorySecretStore();
      final settings = SecureSettingsRepository(secretStore: store);
      await settings.saveGeminiApiKey('unit-gemini-key');
      final client = FakeVisionClient(
        response:
            '{"candidates":[{"title":"CATAN","publisher":"KOSMOS","confidence":0.9}]}',
      );
      final repository = BoxRecognitionRepository(
        settings: settings,
        client: client,
      );

      final result = await repository.recognize(_onePixelPng());

      expect(result.status, BoxRecognitionStatus.candidates);
      expect(result.candidates.single.title, 'CATAN');
      expect(client.lastPrompt, contains('Return JSON only'));
      expect(client.lastJpegBytes, isNotEmpty);
    },
  );
}

List<int> _onePixelPng() {
  return img.encodePng(img.Image(width: 1, height: 1));
}

class FakeVisionClient implements VisionClient {
  FakeVisionClient({this.response = '{"candidates":[]}', this.error});

  final String response;
  final Object? error;
  int callCount = 0;
  String? lastPrompt;
  List<int>? lastJpegBytes;

  @override
  Future<String> recognizeBoxCover({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  }) async {
    callCount += 1;
    lastPrompt = prompt;
    lastJpegBytes = jpegBytes;
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return response;
  }

  @override
  Future<String> recognizeShelf({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  }) async {
    throw UnimplementedError();
  }
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
