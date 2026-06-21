import 'package:dio/dio.dart';

import '../../core/constants.dart';

abstract interface class GameUpcCsvTransport {
  Future<String> fetchCsv();
}

class DioGameUpcCsvTransport implements GameUpcCsvTransport {
  DioGameUpcCsvTransport({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<String> fetchCsv() async {
    try {
      final response = await _dio.get<String>(
        AppConstants.gameUpcCsvDumpUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {
            'Accept': 'text/csv',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) BoardGameShelf/1.0',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final body = response.data;
      if (body == null || body.isEmpty) {
        throw const GameUpcCsvException('Empty response body');
      }
      return body;
    } on GameUpcCsvException {
      rethrow;
    } on DioException catch (error) {
      throw GameUpcCsvException(error.message ?? error.type.name);
    }
  }
}

class GameUpcCsvException implements Exception {
  const GameUpcCsvException(this.message);

  final String message;

  @override
  String toString() => 'GameUpcCsvException: $message';
}
