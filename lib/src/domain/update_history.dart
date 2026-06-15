import 'dart:convert';

import 'game_rank.dart';

class UpdateHistoryEntry {
  const UpdateHistoryEntry({
    required this.date,
    this.averageRating,
    this.weight,
    this.ranks = const [],
  });

  factory UpdateHistoryEntry.fromJson(Map<String, Object?> json) {
    return UpdateHistoryEntry(
      date: json['date'] as String? ?? '',
      averageRating: json['average_rating'] as String?,
      weight: json['weight'] as String?,
      ranks: [
        for (final value in json['ranks'] as List? ?? const [])
          if (value is Map<String, Object?>) GameRank.fromJson(value),
      ],
    );
  }

  final String date;
  final String? averageRating;
  final String? weight;
  final List<GameRank> ranks;

  bool get hasChanges =>
      averageRating != null || weight != null || ranks.isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'date': date,
      if (averageRating != null) 'average_rating': averageRating,
      if (weight != null) 'weight': weight,
      if (ranks.isNotEmpty) 'ranks': [for (final rank in ranks) rank.toJson()],
    };
  }
}

class UpdateHistory {
  const UpdateHistory(this.entries);

  factory UpdateHistory.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const FormatException('update history must be a JSON array');
    }
    return UpdateHistory([
      for (final value in decoded)
        if (value is Map<String, Object?>) UpdateHistoryEntry.fromJson(value),
    ]);
  }

  final List<UpdateHistoryEntry> entries;

  UpdateHistory append(UpdateHistoryEntry entry) {
    if (!entry.hasChanges) {
      return this;
    }
    return UpdateHistory([...entries, entry]);
  }

  String toJsonString() =>
      jsonEncode([for (final entry in entries) entry.toJson()]);
}
