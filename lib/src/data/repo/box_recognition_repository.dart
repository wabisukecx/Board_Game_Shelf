import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import '../../core/constants.dart';
import '../settings/secure_settings_repository.dart';
import '../vision/gemini_vision_service.dart';

class BoxRecognitionRepository {
  BoxRecognitionRepository({
    required SecureSettingsRepository settings,
    required VisionClient client,
  }) : _settings = settings,
       _client = client;

  static const String prompt =
      'Analyze this single board game box cover image. '
      'Return JSON only, with no markdown and no preface. '
      'Schema: {"candidates":[{"title":string,'
      '"japaneseTitle"?:string,"publisher"?:string,'
      '"confidence":number}],"note"?:string}. '
      'Return at most ${AppConstants.visionMaxCandidates} candidates. '
      'Do not guess a BoardGameGeek ID.';

  final SecureSettingsRepository _settings;
  final VisionClient _client;

  Future<BoxRecognitionResult> recognize(List<int> imageBytes) async {
    final apiKey = await _settings.readGeminiApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const BoxRecognitionResult(
        status: BoxRecognitionStatus.missingApiKey,
        candidates: [],
      );
    }

    final jpegBytes = preprocessBoxImage(imageBytes);
    if (jpegBytes == null) {
      return const BoxRecognitionResult(
        status: BoxRecognitionStatus.failed,
        candidates: [],
      );
    }

    try {
      final response = await _client.recognizeBoxCover(
        apiKey: apiKey,
        prompt: prompt,
        jpegBytes: jpegBytes,
      );
      final parsed = parseVisionJson(response);
      if (parsed.candidates.isEmpty) {
        return BoxRecognitionResult(
          status: BoxRecognitionStatus.lowConfidence,
          candidates: const [],
          note: parsed.note,
        );
      }
      final confident = parsed.candidates
          .where(
            (candidate) =>
                candidate.confidence >= AppConstants.visionConfidenceThreshold,
          )
          .take(AppConstants.visionMaxCandidates)
          .toList(growable: false);
      if (confident.isEmpty) {
        return BoxRecognitionResult(
          status: BoxRecognitionStatus.lowConfidence,
          candidates: parsed.candidates
              .take(AppConstants.visionMaxCandidates)
              .toList(),
          note: parsed.note,
        );
      }
      return BoxRecognitionResult(
        status: BoxRecognitionStatus.candidates,
        candidates: confident,
        note: parsed.note,
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const BoxRecognitionResult(
          status: BoxRecognitionStatus.noNetwork,
          candidates: [],
        );
      }
      return const BoxRecognitionResult(
        status: BoxRecognitionStatus.failed,
        candidates: [],
      );
    } on SocketException {
      return const BoxRecognitionResult(
        status: BoxRecognitionStatus.noNetwork,
        candidates: [],
      );
    } catch (_) {
      return const BoxRecognitionResult(
        status: BoxRecognitionStatus.failed,
        candidates: [],
      );
    }
  }
}

List<int>? preprocessBoxImage(List<int> imageBytes) {
  return preprocessVisionImage(
    imageBytes,
    maxLongEdge: AppConstants.visionImageMaxLongEdge,
  );
}

List<int>? preprocessVisionImage(
  List<int> imageBytes, {
  required int maxLongEdge,
}) {
  final decoded = img.decodeImage(Uint8List.fromList(imageBytes));
  if (decoded == null) {
    return null;
  }
  final longEdge = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final resized = longEdge > maxLongEdge
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxLongEdge : null,
          height: decoded.height > decoded.width ? maxLongEdge : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;
  return img.encodeJpg(resized, quality: AppConstants.visionJpegQuality);
}

VisionParseResult parseVisionJson(
  String source, {
  String arrayKey = 'candidates',
  int limit = AppConstants.visionMaxCandidates,
}) {
  final trimmed = source.trim();
  final jsonText = _stripCodeFence(trimmed);
  final decoded = jsonDecode(jsonText);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Vision JSON must be an object');
  }
  final rawCandidates = decoded[arrayKey];
  if (rawCandidates is! List) {
    throw FormatException('Vision JSON $arrayKey must be a list');
  }
  final candidates = <BoxRecognitionCandidate>[];
  for (final raw in rawCandidates) {
    if (raw is! Map) {
      continue;
    }
    final title = raw['title'];
    final confidence = raw['confidence'];
    if (title is! String || title.trim().isEmpty) {
      continue;
    }
    final confidenceValue = switch (confidence) {
      num value => value.toDouble(),
      String value => double.tryParse(value),
      _ => null,
    };
    if (confidenceValue == null) {
      continue;
    }
    candidates.add(
      BoxRecognitionCandidate(
        title: title.trim(),
        japaneseTitle: _optionalString(raw['japaneseTitle']),
        publisher: _optionalString(raw['publisher']),
        confidence: confidenceValue.clamp(0, 1).toDouble(),
        positionHint: _optionalString(raw['positionHint']),
      ),
    );
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  return VisionParseResult(
    candidates: candidates.take(limit).toList(),
    note: _optionalString(decoded['note']),
  );
}

String searchQueryForCandidate(BoxRecognitionCandidate candidate) {
  final parts = <String>[
    candidate.title,
    if (candidate.publisher != null) candidate.publisher!,
  ];
  return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _stripCodeFence(String value) {
  if (!value.startsWith('```')) {
    return value;
  }
  return value
      .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s*```$'), '')
      .trim();
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class VisionParseResult {
  const VisionParseResult({required this.candidates, this.note});

  final List<BoxRecognitionCandidate> candidates;
  final String? note;
}

class BoxRecognitionResult {
  const BoxRecognitionResult({
    required this.status,
    required this.candidates,
    this.note,
  });

  final BoxRecognitionStatus status;
  final List<BoxRecognitionCandidate> candidates;
  final String? note;
}

class BoxRecognitionCandidate {
  const BoxRecognitionCandidate({
    required this.title,
    required this.confidence,
    this.japaneseTitle,
    this.publisher,
    this.positionHint,
  });

  final String title;
  final String? japaneseTitle;
  final String? publisher;
  final double confidence;
  final String? positionHint;
}

enum BoxRecognitionStatus {
  candidates,
  lowConfidence,
  missingApiKey,
  noNetwork,
  failed,
}
