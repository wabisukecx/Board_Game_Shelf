import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants.dart';

abstract interface class VisionClient {
  Future<String> recognizeBoxCover({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  });

  Future<String> recognizeShelf({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  });
}

class GeminiVisionClient implements VisionClient {
  GeminiVisionClient({
    Dio? dio,
    this.model = AppConstants.geminiVisionModel,
    this.endpointBase = 'https://generativelanguage.googleapis.com/v1beta',
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String model;
  final String endpointBase;

  @override
  Future<String> recognizeBoxCover({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  }) async {
    return _generateContent(
      apiKey: apiKey,
      prompt: prompt,
      jpegBytes: jpegBytes,
    );
  }

  @override
  Future<String> recognizeShelf({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  }) async {
    return _generateContent(
      apiKey: apiKey,
      prompt: prompt,
      jpegBytes: jpegBytes,
    );
  }

  Future<String> _generateContent({
    required String apiKey,
    required String prompt,
    required List<int> jpegBytes,
  }) async {
    final response = await _dio.post<Map<String, Object?>>(
      '$endpointBase/models/$model:generateContent',
      options: Options(headers: {'x-goog-api-key': apiKey}),
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(jpegBytes),
                },
              },
            ],
          },
        ],
      },
    );
    final candidates = response.data?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const VisionException('Gemini response has no candidates');
    }
    final content = (candidates.first as Map?)?['content'];
    final parts = (content as Map?)?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const VisionException('Gemini response has no parts');
    }
    final text = (parts.first as Map?)?['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const VisionException('Gemini response text is empty');
    }
    return text.trim();
  }
}

class VisionException implements Exception {
  const VisionException(this.message);

  final String message;

  @override
  String toString() => 'VisionException: $message';
}
