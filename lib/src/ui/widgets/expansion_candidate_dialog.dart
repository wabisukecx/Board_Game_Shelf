import 'package:flutter/material.dart';

import '../../data/bgg/bgg_xml_parser.dart';
import '../../i18n/i18n.dart';

Future<void> showExpansionCandidateDialog({
  required BuildContext context,
  required I18n t,
  required List<NamedBggValue> candidates,
  required Future<void> Function(String bggId) onRegister,
}) {
  final remaining = [...candidates];
  String? registeringId;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(t.t('expansion.candidatesTitle')),
        content: SizedBox(
          width: double.maxFinite,
          child: remaining.isEmpty
              ? Text(t.t('expansion.candidatesEmpty'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: remaining.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final candidate = remaining[index];
                    final candidateId = candidate.bggId ?? '';
                    final registering = registeringId == candidateId;
                    return ListTile(
                      title: Text(candidate.name),
                      subtitle: Text('BGG ID: $candidateId'),
                      trailing: registering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed:
                                  registeringId != null || candidateId.isEmpty
                                  ? null
                                  : () async {
                                      setDialogState(
                                        () => registeringId = candidateId,
                                      );
                                      try {
                                        await onRegister(candidateId);
                                        setDialogState(() {
                                          remaining.removeAt(index);
                                          registeringId = null;
                                        });
                                      } catch (_) {
                                        setDialogState(
                                          () => registeringId = null,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                t.t('search.errorGeneric'),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: Text(t.t('expansion.register')),
                            ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: registeringId == null
                ? () => Navigator.of(dialogContext).pop()
                : null,
            child: Text(t.t('expansion.closeCandidates')),
          ),
        ],
      ),
    ),
  );
}
