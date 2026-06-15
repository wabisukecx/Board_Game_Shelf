import '../bgg/bgg_api_client.dart';
import '../bgg/bgg_xml_parser.dart';

class BggCollectionRepository {
  const BggCollectionRepository({
    required BggApi api,
    required BggXmlParser parser,
  }) : _api = api,
       _parser = parser;

  final BggApi _api;
  final BggXmlParser _parser;

  Future<List<BggCollectionItem>> fetchOwned(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw const BggCollectionUsernameRequiredException();
    }
    final source = await _api.collection(username: normalized);
    return _parser.parseCollection(source);
  }
}

class BggCollectionUsernameRequiredException implements Exception {
  const BggCollectionUsernameRequiredException();

  @override
  String toString() => 'BggCollectionUsernameRequiredException';
}
