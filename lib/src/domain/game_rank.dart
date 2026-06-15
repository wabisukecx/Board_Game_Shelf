import 'dart:convert';

class GameRank {
  const GameRank({required this.type, required this.rank});

  factory GameRank.fromJson(Map<String, Object?> json) {
    return GameRank(
      type: json['type'] as String? ?? '',
      rank: json['rank'] as String? ?? '',
    );
  }

  final String type;
  final String rank;

  Map<String, Object?> toJson() => {'type': type, 'rank': rank};
}

class GameRanks {
  const GameRanks(this.values);

  factory GameRanks.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const FormatException('ranks must be a JSON array');
    }
    return GameRanks([
      for (final value in decoded)
        if (value is Map<String, Object?>) GameRank.fromJson(value),
    ]);
  }

  final List<GameRank> values;

  String toJsonString() =>
      jsonEncode([for (final value in values) value.toJson()]);
}
