import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants.dart';

abstract interface class GameUpcClient {
  Future<GameUpcLookupResult> lookup(String upc, {String? search});
  Future<GameUpcLookupResult> vote(GameUpcCandidate candidate, String userId);
}

class DioGameUpcClient implements GameUpcClient {
  DioGameUpcClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.gameUpcBaseUrl,
              responseType: ResponseType.plain,
            ),
          );

  final Dio _dio;

  @override
  Future<GameUpcLookupResult> lookup(String upc, {String? search}) async {
    final response = await _dio.get<Object?>(
      '/upc/$upc',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: _gameUpcTestOptions,
    );
    return _decodeLookupResult(response.data);
  }

  @override
  Future<GameUpcLookupResult> vote(
    GameUpcCandidate candidate,
    String userId,
  ) async {
    final updateUrl = candidate.preferredUpdateUrl;
    if (updateUrl == null || updateUrl.isEmpty) {
      throw const GameUpcException('Missing update URL');
    }
    final response = await _dio.post<Object?>(
      updateUrl,
      data: {'user_id': userId},
      options: _gameUpcTestOptions,
    );
    return _decodeLookupResult(response.data);
  }
}

GameUpcLookupResult _decodeLookupResult(Object? data) {
  if (data is Map<String, Object?>) {
    return GameUpcLookupResult.fromJson(data);
  }
  if (data is Map) {
    return GameUpcLookupResult.fromJson(Map<String, Object?>.from(data));
  }

  final source = data?.toString() ?? '{}';
  try {
    return GameUpcLookupResult.fromJson(
      jsonDecode(source) as Map<String, Object?>,
    );
  } on FormatException catch (e) {
    final body = source.substring(0, source.length > 200 ? 200 : source.length);
    throw FormatException(e.message, body, e.offset);
  }
}

class GameUpcLookupResult {
  const GameUpcLookupResult({
    required this.upc,
    required this.status,
    required this.bggInfoStatus,
    required this.searchedFor,
    required this.candidates,
  });

  factory GameUpcLookupResult.fromJson(Map<String, Object?> json) {
    final candidates = <GameUpcCandidate>[];
    final rawCandidates = json['bgg_info'];
    if (rawCandidates is List) {
      for (final rawCandidate in rawCandidates) {
        if (rawCandidate is Map<String, Object?>) {
          candidates.add(GameUpcCandidate.fromJson(rawCandidate));
        } else if (rawCandidate is Map) {
          candidates.add(
            GameUpcCandidate.fromJson(Map<String, Object?>.from(rawCandidate)),
          );
        }
      }
    }
    return GameUpcLookupResult(
      upc: json['upc']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      bggInfoStatus:
          (json['bgg_info_status'] ?? json['bgg_status'])?.toString() ?? '',
      searchedFor: json['searched_for']?.toString() ?? '',
      candidates: candidates,
    );
  }

  final String upc;
  final String status;
  final String bggInfoStatus;
  final String searchedFor;
  final List<GameUpcCandidate> candidates;

  bool get isVerified =>
      bggInfoStatus == AppConstants.gameUpcVerifiedStatus &&
      candidates.isNotEmpty;
}

class GameUpcCandidate {
  const GameUpcCandidate({
    required this.bggId,
    required this.name,
    required this.confidence,
    this.thumbnailUrl,
    this.updateUrl,
    this.versions = const [],
  });

  factory GameUpcCandidate.fromJson(Map<String, Object?> json) {
    return GameUpcCandidate(
      bggId: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      confidence: int.tryParse(json['confidence']?.toString() ?? '') ?? 0,
      thumbnailUrl: (json['thumbnail_url'] ?? json['thumbail_url'])?.toString(),
      updateUrl: json['update_url']?.toString(),
      versions: _versionsFromJson(json['versions']),
    );
  }

  final String bggId;
  final String name;
  final int confidence;
  final String? thumbnailUrl;
  final String? updateUrl;
  final List<GameUpcVersion> versions;

  GameUpcVersion? get preferredVersion {
    if (versions.isEmpty) {
      return null;
    }
    return versions.where((version) => version.isJapanese).firstOrNull ??
        versions.where((version) => version.isEnglish).firstOrNull ??
        versions.first;
  }

  String? get preferredUpdateUrl => preferredVersion?.updateUrl ?? updateUrl;
  String get preferredVersionLabel => preferredVersion?.name ?? name;
}

class GameUpcVersion {
  const GameUpcVersion({
    required this.name,
    required this.versionId,
    required this.confidence,
    this.language,
    this.updateUrl,
  });

  factory GameUpcVersion.fromJson(Map<String, Object?> json) {
    return GameUpcVersion(
      name: json['name']?.toString() ?? '',
      versionId: json['version_id']?.toString() ?? '',
      confidence: int.tryParse(json['confidence']?.toString() ?? '') ?? 0,
      language: json['language']?.toString(),
      updateUrl: json['update_url']?.toString(),
    );
  }

  final String name;
  final String versionId;
  final int confidence;
  final String? language;
  final String? updateUrl;

  bool get isJapanese {
    final value = (language ?? name).toLowerCase();
    return value.contains('japanese') ||
        value == 'ja' ||
        value == 'jp' ||
        value.contains('日本');
  }

  bool get isEnglish {
    final value = (language ?? name).toLowerCase();
    return value.contains('english') || value == 'en';
  }
}

List<GameUpcVersion> _versionsFromJson(Object? rawVersions) {
  if (rawVersions is! List) {
    return const [];
  }
  return [
    for (final rawVersion in rawVersions)
      if (rawVersion is Map<String, Object?>)
        GameUpcVersion.fromJson(rawVersion)
      else if (rawVersion is Map)
        GameUpcVersion.fromJson(Map<String, Object?>.from(rawVersion)),
  ];
}

class GameUpcException implements Exception {
  const GameUpcException(this.message);

  final String message;

  @override
  String toString() => 'GameUpcException: $message';
}

final _gameUpcTestOptions = Options(
  responseType: ResponseType.plain,
  headers: const {'x-api-key': 'test_test_test_test_test'},
);
