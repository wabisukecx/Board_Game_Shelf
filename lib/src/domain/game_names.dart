import 'dart:convert';

class GameNames {
  const GameNames({
    required this.primary,
    this.japanese,
    this.english,
    this.alternates = const [],
  });

  factory GameNames.fromJson(Map<String, Object?> json) {
    return GameNames(
      primary: json['primary'] as String? ?? '',
      japanese: json['japanese'] as String?,
      english: json['english'] as String?,
      alternates: [
        for (final value in json['alternates'] as List? ?? const [])
          if (value is String) value,
      ],
    );
  }

  factory GameNames.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('names must be a JSON object');
    }
    return GameNames.fromJson(decoded);
  }

  final String primary;
  final String? japanese;
  final String? english;
  final List<String> alternates;

  Map<String, Object?> toJson() {
    return {
      'primary': primary,
      'japanese': japanese,
      'english': english,
      'alternates': dedupeAlternates(alternates),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static List<String> dedupeAlternates(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      if (seen.add(value)) {
        result.add(value);
      }
    }
    return result;
  }
}
