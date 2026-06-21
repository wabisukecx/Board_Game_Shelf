import 'dart:convert';

import 'package:dio/dio.dart';

import 'bgg_xml_parser.dart';

abstract interface class BggRelationshipSource {
  Future<List<NamedBggValue>> registrationCandidates(String bggId);
}

class DioBggRelationshipSource implements BggRelationshipSource {
  DioBggRelationshipSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.geekdo.com',
              responseType: ResponseType.plain,
              followRedirects: true,
            ),
          );

  final Dio _dio;

  @override
  Future<List<NamedBggValue>> registrationCandidates(String bggId) async {
    final response = await _dio.get<String>(
      '/api/geekitems',
      queryParameters: {'objectid': bggId, 'objecttype': 'thing'},
    );
    return parseBggRegistrationCandidates(response.data ?? '');
  }
}

List<NamedBggValue> parseBggRegistrationCandidates(String source) {
  final root = jsonDecode(source);
  if (root is! Map<String, dynamic>) {
    throw const FormatException('BGG relationship response is not an object');
  }
  final item = root['item'];
  if (item is! Map<String, dynamic>) {
    throw const FormatException('BGG relationship response has no item');
  }
  final links = item['links'];
  if (links is! Map<String, dynamic>) {
    return const [];
  }

  final subtype = item['subtype'];
  final relationshipKey = subtype == 'boardgameexpansion'
      ? 'expandsboardgame'
      : 'boardgameexpansion';
  final values = links[relationshipKey];
  if (values is! List) {
    return const [];
  }

  return [
    for (final value in values)
      if (value is Map<String, dynamic>)
        if (value['objectid'] case final Object id)
          NamedBggValue(
            name: value['name']?.toString() ?? '',
            bggId: id.toString(),
          ),
  ];
}
