import 'package:dio/dio.dart';

import '../../core/constants.dart';

class BggRequest {
  const BggRequest({
    required this.path,
    this.queryParameters = const {},
    this.headers = const {},
  });

  final String path;
  final Map<String, Object?> queryParameters;
  final Map<String, String> headers;
}

class BggResponse {
  const BggResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;

  String? header(String name) {
    final lower = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lower) {
        return entry.value;
      }
    }
    return null;
  }
}

class BggTransportException implements Exception {
  const BggTransportException(this.message);

  final String message;

  @override
  String toString() => 'BggTransportException: $message';
}

abstract interface class BggTransport {
  Future<BggResponse> get(BggRequest request);
}

class DioBggTransport implements BggTransport {
  DioBggTransport({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://${AppConstants.bggHost}',
              responseType: ResponseType.plain,
              followRedirects: true,
            ),
          );

  final Dio _dio;

  @override
  Future<BggResponse> get(BggRequest request) async {
    try {
      final response = await _dio.get<Object?>(
        request.path,
        queryParameters: request.queryParameters,
        options: Options(headers: request.headers),
      );
      return BggResponse(
        statusCode: response.statusCode ?? 0,
        body: response.data?.toString() ?? '',
        headers: {
          for (final entry in response.headers.map.entries)
            if (entry.value.isNotEmpty) entry.key: entry.value.first,
        },
      );
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        return BggResponse(
          statusCode: response.statusCode ?? 0,
          body: response.data?.toString() ?? '',
          headers: {
            for (final entry in response.headers.map.entries)
              if (entry.value.isNotEmpty) entry.key: entry.value.first,
          },
        );
      }
      throw BggTransportException(error.message ?? error.type.name);
    }
  }
}
