import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../settings/secure_settings_repository.dart';
import '../vision/gemini_vision_service.dart';
import 'box_recognition_repository.dart';

class ShelfRecognitionRepository {
  ShelfRecognitionRepository({
    required SecureSettingsRepository settings,
    required VisionClient client,
  }) : _settings = settings,
       _client = client;

  static const String prompt =
      'Analyze this photo of a board game shelf or multiple board game boxes. '
      'Do not detect objects, crop the image, or return bounding boxes. '
      'Return JSON only, with no markdown and no preface. '
      'Schema: {"detections":[{"title":string,'
      '"japaneseTitle"?:string,"publisher"?:string,'
      '"confidence":number,"positionHint"?:string}],"note"?:string}. '
      'Return at most ${AppConstants.shelfMaxDetections} detections. '
      'Use positionHint only as a human-readable hint such as "upper left". '
      'Do not guess a BoardGameGeek ID.';

  final SecureSettingsRepository _settings;
  final VisionClient _client;

  Future<ShelfRecognitionResult> recognizeShelf(List<int> imageBytes) async {
    final apiKey = await _settings.readGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const ShelfRecognitionResult(
        status: ShelfRecognitionStatus.missingApiKey,
        detections: [],
      );
    }

    final jpegBytes = preprocessVisionImage(
      imageBytes,
      maxLongEdge: AppConstants.shelfImageMaxLongEdge,
    );
    if (jpegBytes == null) {
      return const ShelfRecognitionResult(
        status: ShelfRecognitionStatus.failed,
        detections: [],
      );
    }

    try {
      final response = await _client.recognizeShelf(
        apiKey: apiKey,
        prompt: prompt,
        jpegBytes: jpegBytes,
      );
      final parsed = parseVisionJson(
        response,
        arrayKey: 'detections',
        limit: AppConstants.shelfMaxDetections,
      );
      if (parsed.candidates.isEmpty) {
        return ShelfRecognitionResult(
          status: ShelfRecognitionStatus.empty,
          detections: const [],
          note: parsed.note,
        );
      }
      final detections = parsed.candidates
          .take(AppConstants.shelfMaxDetections)
          .toList(growable: false);
      final hasConfident = detections.any(
        (candidate) =>
            candidate.confidence >= AppConstants.visionConfidenceThreshold,
      );
      return ShelfRecognitionResult(
        status: hasConfident
            ? ShelfRecognitionStatus.detections
            : ShelfRecognitionStatus.lowConfidence,
        detections: detections,
        note: parsed.note,
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const ShelfRecognitionResult(
          status: ShelfRecognitionStatus.noNetwork,
          detections: [],
        );
      }
      return const ShelfRecognitionResult(
        status: ShelfRecognitionStatus.failed,
        detections: [],
      );
    } on SocketException {
      return const ShelfRecognitionResult(
        status: ShelfRecognitionStatus.noNetwork,
        detections: [],
      );
    } catch (_) {
      return const ShelfRecognitionResult(
        status: ShelfRecognitionStatus.failed,
        detections: [],
      );
    }
  }
}

class ShelfRecognitionResult {
  const ShelfRecognitionResult({
    required this.status,
    required this.detections,
    this.note,
  });

  final ShelfRecognitionStatus status;
  final List<BoxRecognitionCandidate> detections;
  final String? note;
}

enum ShelfRecognitionStatus {
  detections,
  lowConfidence,
  empty,
  missingApiKey,
  noNetwork,
  failed,
}
