import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/repo/box_recognition_repository.dart';
import 'package:bg_shelf_scanner/src/data/repo/shelf_recognition_repository.dart';
import 'package:bg_shelf_scanner/src/data/settings/secret_store.dart';
import 'package:bg_shelf_scanner/src/data/settings/secure_settings_repository.dart';
import 'package:bg_shelf_scanner/src/data/vision/gemini_vision_service.dart';

void main() {
  test('parses C-30 detections, sorts by confidence, and limits to 30', () {
    final detections = List.generate(
      35,
      (index) =>
          '{"title":"Game $index","confidence":${(35 - index) / 100},'
          '"positionHint":"row $index"}',
    ).join(',');
    final parsed = parseVisionJson(
      '{"detections":[$detections],"note":"shelf"}',
      arrayKey: 'detections',
      limit: AppConstants.shelfMaxDetections,
    );

    expect(parsed.note, 'shelf');
    expect(parsed.candidates, hasLength(AppConstants.shelfMaxDetections));
    expect(parsed.candidates.first.title, 'Game 0');
    expect(parsed.candidates.first.positionHint, 'row 0');
  });

  test('preprocesses shelf image to JPEG with long edge at most 1600', () {
    final source = img.Image(width: 2400, height: 1200)
      ..clear(img.ColorRgb8(0, 255, 0));

    final bytes = preprocessVisionImage(
      img.encodePng(source),
      maxLongEdge: AppConstants.shelfImageMaxLongEdge,
    );
    final decoded = img.decodeImage(Uint8List.fromList(bytes!));

    expect(decoded, isNotNull);
    expect(decoded!.width, AppConstants.shelfImageMaxLongEdge);
    expect(decoded.height, 800);
  });

  test(
    'missing Gemini key returns missingApiKey without calling client',
    () async {
      final client = FakeShelfVisionClient();
      final repository = ShelfRecognitionRepository(
        settings: SecureSettingsRepository(secretStore: MemorySecretStore()),
        client: client,
      );

      final result = await repository.recognizeShelf(_onePixelPng());

      expect(result.status, ShelfRecognitionStatus.missingApiKey);
      expect(client.shelfCallCount, 0);
    },
  );

  test('low confidence detections are kept and flagged by status', () async {
    final settings = await _settingsWithGeminiKey();
    final repository = ShelfRecognitionRepository(
      settings: settings,
      client: FakeShelfVisionClient(
        response:
            '{"detections":[{"title":"Maybe","confidence":0.2,"positionHint":"left"}]}',
      ),
    );

    final result = await repository.recognizeShelf(_onePixelPng());

    expect(result.status, ShelfRecognitionStatus.lowConfidence);
    expect(result.detections.single.title, 'Maybe');
    expect(result.detections.single.confidence, 0.2);
  });

  test(
    'confident detections return detections and prompt requests JSON only',
    () async {
      final settings = await _settingsWithGeminiKey();
      final client = FakeShelfVisionClient(
        response:
            '{"detections":[{"title":"Azul","publisher":"Plan B","confidence":0.91}]}',
      );
      final repository = ShelfRecognitionRepository(
        settings: settings,
        client: client,
      );

      final result = await repository.recognizeShelf(_onePixelPng());

      expect(result.status, ShelfRecognitionStatus.detections);
      expect(result.detections.single.title, 'Azul');
      expect(searchQueryForCandidate(result.detections.single), 'Azul Plan B');
      expect(client.lastPrompt, contains('Return JSON only'));
      expect(client.lastPrompt, contains('Do not guess a BoardGameGeek ID'));
      expect(client.lastPrompt, contains('detections'));
      expect(client.lastJpegBytes, isNotEmpty);
    },
  );

  test('empty detections returns empty status', () async {
    final settings = await _settingsWithGeminiKey();
    final repository = ShelfRecognitionRepository(
      settings: settings,
      client: FakeShelfVisionClient(response: '{"detections":[]}'),
    );

    final result = await repository.recognizeShelf(_onePixelPng());

    expect(result.status, ShelfRecognitionStatus.empty);
    expect(result.detections, isEmpty);
  });

  test('network exception returns noNetwork', () async {
    final settings = await _settingsWithGeminiKey();
    final repository = ShelfRecognitionRepository(
      settings: settings,
      client: FakeShelfVisionClient(
        error: DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
          error: const SocketException('offline'),
        ),
      ),
    );

    final result = await repository.recognizeShelf(_onePixelPng());

    expect(result.status, ShelfRecognitionStatus.noNetwork);
  });
}

Future<SecureSettingsRepository> _settingsWithGeminiKey() async {
  final settings = SecureSettingsRepository(secretStore: MemorySecretStore());
  await settings.saveGeminiApiKey('unit-gemini-key');
  return settings;
}

List<int> _onePixelPng() {
  return img.encodePng(img.Image(width: 1, height: 1));
}

class FakeShelfVisionClient implements VisionClient {
  FakeShelfVisionClient({this.response = '{"detections":[]}', this.error});

  final String response;
  final Object? error;
  int shelfCallCount = 0;
  String? lastPrompt;
  List<int>? lastJpegBytes;

  @override
  Future<String> recognizeBoxCover({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String> recognizeShelf({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  }) async {
    shelfCallCount += 1;
    lastPrompt = prompt;
    lastJpegBytes = jpegBytes;
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return response;
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
