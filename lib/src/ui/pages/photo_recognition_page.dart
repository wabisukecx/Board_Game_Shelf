import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../data/repo/box_recognition_repository.dart';
import 'search_registration_page.dart';
import 'settings_page.dart';

class PhotoRecognitionPage extends ConsumerStatefulWidget {
  const PhotoRecognitionPage({super.key});

  @override
  ConsumerState<PhotoRecognitionPage> createState() =>
      _PhotoRecognitionPageState();
}

class _PhotoRecognitionPageState extends ConsumerState<PhotoRecognitionPage> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _recognizing = false;
  BoxRecognitionResult? _result;
  String? _message;

  bool get _androidCameraSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _image = picked;
      _result = null;
      _message = null;
    });
  }

  Future<void> _recognize() async {
    final image = _image;
    if (image == null || _recognizing) {
      return;
    }
    final t = ref.read(i18nProvider);
    setState(() {
      _recognizing = true;
      _message = null;
      _result = null;
    });
    try {
      final result = await ref
          .read(boxRecognitionRepositoryProvider)
          .recognize(await image.readAsBytes());
      if (!mounted) return;
      setState(() {
        _result = result;
        _message = switch (result.status) {
          BoxRecognitionStatus.candidates => null,
          BoxRecognitionStatus.lowConfidence => t.t('photo.lowConfidence'),
          BoxRecognitionStatus.missingApiKey => t.t('photo.missingApiKey'),
          BoxRecognitionStatus.noNetwork => t.t('photo.noNetwork'),
          BoxRecognitionStatus.failed => t.t('photo.failed'),
        };
      });
    } finally {
      if (mounted) {
        setState(() => _recognizing = false);
      }
    }
  }

  void _openSearch(String query) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            SearchRegistrationPage(initialQuery: query, autoSearch: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('photo.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _androidCameraSupported
                      ? () => _pick(ImageSource.camera)
                      : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(t.t('photo.takePhoto')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t.t('photo.pickGallery')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _preview(t),
          const SizedBox(height: 16),
          Text(t.t('photo.sendNotice')),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _image == null || _recognizing ? null : _recognize,
            icon: _recognizing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(t.t('photo.recognize')),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openSearch(''),
                  icon: const Icon(Icons.search),
                  label: Text(t.t('photo.manualSearch')),
                ),
                if (result?.status == BoxRecognitionStatus.missingApiKey)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                    icon: const Icon(Icons.settings),
                    label: Text(t.t('photo.openSettings')),
                  ),
              ],
            ),
          ],
          if (result != null && result.candidates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              t.t('photo.candidates'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final candidate in result.candidates)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(candidate.title),
                  subtitle: Text(_candidateSubtitle(t, candidate)),
                  trailing: const Icon(Icons.search),
                  onTap: () => _openSearch(searchQueryForCandidate(candidate)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _preview(dynamic t) {
    final image = _image;
    if (image == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.image_outlined, size: 48),
              const SizedBox(height: 8),
              Text(t.t('photo.noImage')),
            ],
          ),
        ),
      );
    }
    if (kIsWeb) {
      return Image.network(image.path, height: 260, fit: BoxFit.contain);
    }
    return Image.file(File(image.path), height: 260, fit: BoxFit.contain);
  }

  String _candidateSubtitle(dynamic t, BoxRecognitionCandidate candidate) {
    final parts = <String>[
      t.t('photo.confidence', {'value': (candidate.confidence * 100).round()}),
      if (candidate.japaneseTitle != null) candidate.japaneseTitle!,
      if (candidate.publisher != null) candidate.publisher!,
    ];
    return parts.join(' / ');
  }
}
