import 'package:flutter/material.dart';

import '../../data/bgg/bgg_xml_parser.dart';
import '../../i18n/i18n.dart';

Future<NamedBggValue?> showParentGameCandidateDialog({
  required BuildContext context,
  required I18n t,
  required List<NamedBggValue> candidates,
}) {
  return showDialog<NamedBggValue>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.t('expansion.parentCandidatesTitle')),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.t('expansion.parentCandidatesBody')),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: candidates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final candidate = candidates[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(candidate.name),
                    subtitle: candidate.bggId == null
                        ? null
                        : Text('BGG ID: ${candidate.bggId}'),
                    trailing: TextButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(candidate),
                      child: Text(t.t('expansion.parentChoose')),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t.t('expansion.parentDecideLater')),
        ),
      ],
    ),
  );
}
