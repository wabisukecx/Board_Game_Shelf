import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/gameupc/game_upc_client.dart';

void main() {
  test('sends GameUPC test API header for lookup and vote', () async {
    final headers = <String?>[];
    final dio = Dio(BaseOptions(responseType: ResponseType.plain));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          headers.add(options.headers['x-api-key']?.toString());
          handler.resolve(
            Response<String>(
              requestOptions: options,
              statusCode: 200,
              data: '''
{
  "status": "ok",
  "upc": "4571394091432",
  "searched_for": "Fallout",
  "bgg_info_status": "choose_from_bgg_info_or_search",
  "bgg_info": [
    {
      "id": 372413,
      "name": "Meat Master",
      "confidence": 4,
      "update_url": "https://api.gameupc.com/test/upc/4571394091432/bgg_id/372413",
      "versions": [
        {
          "version_id": 635288,
          "name": "Meat Master",
          "language": "Japanese",
          "confidence": 99,
          "update_url": "https://api.gameupc.com/test/upc/4571394091432/bgg_id/372413/version/635288"
        }
      ]
    }
  ]
}
''',
            ),
          );
        },
      ),
    );
    final client = DioGameUpcClient(dio: dio);

    final result = await client.lookup('4571394091432');
    await client.vote(result.candidates.single, 'unit-user');

    expect(headers, ['test_test_test_test_test', 'test_test_test_test_test']);
  });

  test('parses verified GameUPC response', () {
    final result = GameUpcLookupResult.fromJson(const {
      'status': 'ok',
      'upc': '019962194719',
      'searched_for': 'Gloomhaven',
      'bgg_info_status': 'verified',
      'bgg_info': [
        {
          'id': 174430,
          'name': 'Gloomhaven',
          'confidence': 96,
          'thumbnail_url': 'https://example.test/thumb.jpg',
          'update_url':
              'https://api.gameupc.com/test/upc/019962194719/bgg_id/174430',
        },
      ],
    });

    expect(result.isVerified, isTrue);
    expect(result.candidates.single.bggId, '174430');
    expect(result.candidates.single.name, 'Gloomhaven');
    expect(result.candidates.single.confidence, 96);
    expect(result.candidates.single.thumbnailUrl, contains('thumb.jpg'));
  });

  test('parses already decoded Dio JSON map response', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, Object?>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'status': 'ok',
                'upc': '111111111117',
                'searched_for': 'Splendor',
                'bgg_info_status': 'verified',
                'bgg_info': [
                  {'id': 148228, 'name': 'Splendor', 'confidence': 99},
                ],
              },
            ),
          );
        },
      ),
    );
    final client = DioGameUpcClient(dio: dio);

    final result = await client.lookup('111111111117');

    expect(result.isVerified, isTrue);
    expect(result.candidates.single.bggId, '148228');
  });

  test('prefers Japanese version update URL then English version', () {
    final result = GameUpcLookupResult.fromJson(const {
      'status': 'ok',
      'upc': '019962194719',
      'searched_for': 'Gloomhaven',
      'bgg_info_status': 'choose_from_bgg_info_or_search',
      'bgg_info': [
        {
          'id': 174430,
          'name': 'Gloomhaven',
          'confidence': 80,
          'update_url': 'https://example.test/game',
          'versions': [
            {
              'name': 'Gloomhaven English edition',
              'version_id': 1,
              'language': 'English',
              'confidence': 90,
              'update_url': 'https://example.test/en',
            },
            {
              'name': 'グルームヘイヴン 完全日本語版',
              'version_id': 2,
              'language': 'Japanese',
              'confidence': 95,
              'update_url': 'https://example.test/ja',
            },
          ],
        },
      ],
    });

    final candidate = result.candidates.single;

    expect(candidate.preferredVersion?.language, 'Japanese');
    expect(candidate.preferredVersionLabel, 'グルームヘイヴン 完全日本語版');
    expect(candidate.preferredUpdateUrl, 'https://example.test/ja');
  });

  test('falls back to English version when Japanese version is absent', () {
    final candidate = GameUpcCandidate.fromJson(const {
      'id': 174430,
      'name': 'Gloomhaven',
      'confidence': 80,
      'versions': [
        {
          'name': 'Gloomhaven German edition',
          'version_id': 3,
          'language': 'German',
          'confidence': 70,
          'update_url': 'https://example.test/de',
        },
        {
          'name': 'Gloomhaven English edition',
          'version_id': 1,
          'language': 'English',
          'confidence': 90,
          'update_url': 'https://example.test/en',
        },
      ],
    });

    expect(candidate.preferredVersion?.language, 'English');
    expect(candidate.preferredUpdateUrl, 'https://example.test/en');
  });

  test('parses choose response and legacy bgg_status field spelling', () {
    final result = GameUpcLookupResult.fromJson(const {
      'status': 'ok',
      'upc': '222222222224',
      'searched_for': 'Tiny Towns',
      'bgg_status': 'choose_from_bgg_info_or_search',
      'bgg_info': [
        {'id': 265736, 'name': 'Tiny Towns', 'confidence': 59},
        {'id': 287576, 'name': 'Tiny Towns: Fortune', 'confidence': 0},
      ],
    });

    expect(result.isVerified, isFalse);
    expect(result.bggInfoStatus, 'choose_from_bgg_info_or_search');
    expect(result.candidates.map((candidate) => candidate.bggId), [
      '265736',
      '287576',
    ]);
  });
}
