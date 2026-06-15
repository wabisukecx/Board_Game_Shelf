import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/collection_analytics.dart';

class AnalyticsDistributionSection extends ConsumerWidget {
  const AnalyticsDistributionSection({
    super.key,
    required this.title,
    required this.distribution,
  });

  final String title;
  final DistributionSummary distribution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return AnalyticsSection(
      title: title,
      note: t.t('dashboard.qualityCount', {
        'included': distribution.includedCount,
        'excluded': distribution.excludedCount,
      }),
      entries: distribution.entries,
    );
  }
}

class AnalyticsRankingSection extends StatelessWidget {
  const AnalyticsRankingSection({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<CountEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSection(title: title, entries: entries);
  }
}

class AnalyticsSection extends ConsumerWidget {
  const AnalyticsSection({
    super.key,
    required this.title,
    required this.entries,
    this.note,
  });

  final String title;
  final List<CountEntry> entries;
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final maxCount = entries.fold<int>(
      0,
      (max, entry) => entry.count > max ? entry.count : max,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayAnalyticsLabel(t, title),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (note != null)
                  Text(note!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(t.t('dashboard.noData'))
            else
              for (final entry in entries)
                AnalyticsBarRow(entry: entry, maxCount: maxCount),
          ],
        ),
      ),
    );
  }
}

class AnalyticsBarRow extends StatelessWidget {
  const AnalyticsBarRow({
    super.key,
    required this.entry,
    required this.maxCount,
  });

  final CountEntry entry;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : entry.count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Consumer(
              builder: (context, ref, _) {
                final t = ref.watch(i18nProvider);
                return Text(
                  displayAnalyticsLabel(t, entry.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0, 1),
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text('${entry.count}', textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

String displayAnalyticsLabel(dynamic t, String label) {
  if (label == CountEntry.unspecifiedLabel) {
    return t.t('dashboard.unspecified');
  }
  if (label.startsWith('learning_curve.') ||
      label.startsWith('player_types.') ||
      label.startsWith('mastery_time.')) {
    return t.t(label);
  }
  return label;
}
