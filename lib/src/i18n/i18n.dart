import 'dart:convert';

typedef TranslationMap = Map<String, Object?>;

class I18n {
  I18n(this._messages);

  factory I18n.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('i18n root must be a JSON object');
    }
    return I18n(decoded);
  }

  final TranslationMap _messages;

  String t(String key, [Map<String, Object?> variables = const {}]) {
    final value = _lookup(key);
    if (value is! String) {
      return key;
    }

    var resolved = value;
    for (final entry in variables.entries) {
      resolved = resolved.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return resolved;
  }

  Object? _lookup(String key) {
    Object? cursor = _messages;
    for (final segment in key.split('.')) {
      if (cursor is! Map<String, Object?> || !cursor.containsKey(segment)) {
        return null;
      }
      cursor = cursor[segment];
    }
    return cursor;
  }
}
