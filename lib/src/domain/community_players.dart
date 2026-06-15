import 'dart:convert';

class SuggestedPlayerVote {
  const SuggestedPlayerVote({
    required this.label,
    required this.best,
    required this.recommended,
    required this.notRecommended,
  });

  factory SuggestedPlayerVote.fromJson(Map<String, Object?> json) {
    return SuggestedPlayerVote(
      label: json['label'] as String? ?? '',
      best: json['best'] as int? ?? 0,
      recommended: json['recommended'] as int? ?? 0,
      notRecommended: json['not_recommended'] as int? ?? 0,
    );
  }

  final String label;
  final int best;
  final int recommended;
  final int notRecommended;

  int get total => best + recommended + notRecommended;

  int get sortValue => int.tryParse(label.replaceAll('+', '')) ?? 0;

  Map<String, Object?> toJson() {
    return {
      'label': label,
      'best': best,
      'recommended': recommended,
      'not_recommended': notRecommended,
    };
  }
}

class SuggestedPlayerVotes {
  const SuggestedPlayerVotes(this.values);

  factory SuggestedPlayerVotes.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const FormatException('suggested players must be a JSON array');
    }
    return SuggestedPlayerVotes([
      for (final value in decoded)
        if (value is Map<String, Object?>) SuggestedPlayerVote.fromJson(value),
    ]);
  }

  final List<SuggestedPlayerVote> values;

  String toJsonString() =>
      jsonEncode([for (final value in values) value.toJson()]);
}
