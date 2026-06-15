import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../data/backup/backup_service.dart';
import '../../i18n/language_preference_repository.dart';
import '../../i18n/locale_option.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _token = TextEditingController();
  final _bggUsername = TextEditingController();
  final _geminiKey = TextEditingController();
  bool _tokenSet = false;
  bool _bggUsernameSet = false;
  bool _geminiSet = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _token.dispose();
    _bggUsername.dispose();
    _geminiKey.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final settings = ref.read(secureSettingsProvider);
    String? token;
    String? bggUsername;
    String? gemini;
    try {
      token = await settings.readToken();
      bggUsername = await settings.readBggUsername();
      gemini = await settings.readGeminiApiKey();
    } catch (_) {
      // Secure storage is unavailable on some platforms/tests; treat as unset.
    }
    if (!mounted) return;
    setState(() {
      _tokenSet = token != null && token.isNotEmpty;
      _bggUsernameSet = bggUsername != null && bggUsername.isNotEmpty;
      _geminiSet = gemini != null && gemini.isNotEmpty;
      _loading = false;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveToken() async {
    final t = ref.read(i18nProvider);
    await ref.read(secureSettingsProvider).saveBggBearerToken(_token.text);
    _token.clear();
    await _loadStatus();
    _snack(t.t('settings.saved'));
  }

  Future<void> _clearToken() async {
    await ref.read(secureSettingsProvider).deleteBggBearerToken();
    await _loadStatus();
  }

  Future<void> _saveBggUsername() async {
    final t = ref.read(i18nProvider);
    await ref.read(secureSettingsProvider).saveBggUsername(_bggUsername.text);
    _bggUsername.clear();
    await _loadStatus();
    _snack(t.t('settings.saved'));
  }

  Future<void> _clearBggUsername() async {
    await ref.read(secureSettingsProvider).deleteBggUsername();
    await _loadStatus();
  }

  Future<void> _saveGemini() async {
    final t = ref.read(i18nProvider);
    await ref.read(secureSettingsProvider).saveGeminiApiKey(_geminiKey.text);
    _geminiKey.clear();
    await _loadStatus();
    _snack(t.t('settings.saved'));
  }

  Future<void> _clearGemini() async {
    await ref.read(secureSettingsProvider).deleteGeminiApiKey();
    await _loadStatus();
  }

  Future<void> _manualBackup() async {
    final t = ref.read(i18nProvider);
    try {
      final documents = await getApplicationDocumentsDirectory();
      final databaseFile = File(
        p.join(documents.path, 'bg_shelf_scanner.sqlite'),
      );
      final backupDir = Directory(p.join(documents.path, 'bg_shelf_backups'));
      final created = await ref
          .read(backupServiceProvider)
          .copyDatabaseBackup(
            databaseFile: databaseFile,
            backupDirectory: backupDir,
            kind: BackupKind.manual,
          );
      _snack(t.t('settings.backupDone', {'path': created.path}));
    } catch (_) {
      _snack(t.t('settings.backupFailed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final guide = ref.watch(tokenGuideProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings.title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  t.t('settings.language'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const _LanguageSelector(),
                const Divider(height: 32),
                Text(
                  t.t('settings.bggToken'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(t.t('settings.tokenGuide')),
                const SizedBox(height: 4),
                SelectableText(guide.bggTokenUrl),
                const SizedBox(height: 4),
                Text(
                  t.t('settings.tokenApprovalNotice'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _tokenSet
                      ? t.t('settings.statusSet')
                      : t.t('settings.statusUnset'),
                  style: TextStyle(
                    color: _tokenSet
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                TextField(
                  controller: _token,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.t('settings.bggToken'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _saveToken,
                      child: Text(t.t('common.save')),
                    ),
                    const SizedBox(width: 8),
                    if (_tokenSet)
                      TextButton(
                        onPressed: _clearToken,
                        child: Text(t.t('settings.clear')),
                      ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  t.t('settings.bggUsername'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(t.t('settings.bggUsernameGuide')),
                const SizedBox(height: 8),
                Text(
                  _bggUsernameSet
                      ? t.t('settings.statusSet')
                      : t.t('settings.statusUnset'),
                  style: TextStyle(
                    color: _bggUsernameSet
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                TextField(
                  controller: _bggUsername,
                  decoration: InputDecoration(
                    labelText: t.t('settings.bggUsername'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _saveBggUsername,
                      child: Text(t.t('common.save')),
                    ),
                    const SizedBox(width: 8),
                    if (_bggUsernameSet)
                      TextButton(
                        onPressed: _clearBggUsername,
                        child: Text(t.t('settings.clear')),
                      ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  t.t('settings.translationOption'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _geminiSet
                      ? t.t('settings.statusSet')
                      : t.t('settings.statusUnset'),
                  style: TextStyle(
                    color: _geminiSet
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                TextField(
                  controller: _geminiKey,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.t('settings.geminiApiKey'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _saveGemini,
                      child: Text(t.t('common.save')),
                    ),
                    const SizedBox(width: 8),
                    if (_geminiSet)
                      TextButton(
                        onPressed: _clearGemini,
                        child: Text(t.t('settings.clear')),
                      ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  t.t('settings.keyNotBundledPolicy'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 32),
                Text(
                  t.t('settings.backup'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _manualBackup,
                  icon: const Icon(Icons.backup),
                  label: Text(t.t('settings.manualBackup')),
                ),
              ],
            ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final options = ref.watch(localeOptionsProvider);
    final preference = ref.watch(languagePreferenceProvider);

    return options.when(
      data: (localeOptions) {
        final savedValue =
            preference.valueOrNull ?? LanguagePreferenceRepository.systemValue;
        final localeCodes = {
          for (final option in localeOptions) option.localeCode,
        };
        final currentValue =
            savedValue == LanguagePreferenceRepository.systemValue ||
                localeCodes.contains(savedValue)
            ? savedValue
            : LanguagePreferenceRepository.systemValue;
        return DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            DropdownMenuItem<String>(
              value: LanguagePreferenceRepository.systemValue,
              child: Text(t.t('settings.languageSystem')),
            ),
            for (final option in localeOptions)
              DropdownMenuItem<String>(
                value: option.localeCode,
                child: Text(_languageLabel(option)),
              ),
          ],
          onChanged: preference.isLoading
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  final controller = ref.read(
                    languagePreferenceProvider.notifier,
                  );
                  if (value == LanguagePreferenceRepository.systemValue) {
                    controller.useSystem();
                  } else {
                    controller.select(value);
                  }
                },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(
        '$error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  String _languageLabel(LocaleOption option) {
    return option.displayName == option.localeCode
        ? option.displayName
        : '${option.displayName} (${option.localeCode})';
  }
}
