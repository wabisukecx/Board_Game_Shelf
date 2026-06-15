import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/play_analytics.dart';
import '../widgets/analytics_sections.dart';
import 'game_detail_page.dart';

class PlayAnalyticsPage extends ConsumerWidget {
  const PlayAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final summaryAsync = ref.watch(playAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('play_analytics.title'))),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$error'),
          ),
        ),
        data: (summary) {
          if (summary.totalSessions == 0) {
            return Center(child: Text(t.t('play_analytics.empty')));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _Overview(summary: summary),
              const SizedBox(height: 16),
              AnalyticsDistributionSection(
                title: t.t('play_analytics.actualPlayingTimeDistribution'),
                distribution: summary.actualPlayingTimeDistribution,
              ),
              AnalyticsRankingSection(
                title: t.t('play_analytics.mechanicsPlayCounts'),
                entries: summary.mechanicsPlayCounts,
              ),
              AnalyticsRankingSection(
                title: t.t('play_analytics.designerPlayCounts'),
                entries: summary.designerPlayCounts,
              ),
              _RatedSection(
                title: t.t('play_analytics.mechanicRatings'),
                entries: summary.mechanicRatings,
              ),
              _RatedSection(
                title: t.t('play_analytics.designerRatings'),
                entries: summary.designerRatings,
              ),
              AnalyticsRankingSection(
                title: t.t('play_analytics.expansionUsage'),
                entries: summary.expansionUsage,
              ),
              _RatedSection(
                title: t.t('play_analytics.ratingByPlayerCount'),
                entries: summary.ratingByPlayerCount,
                appendPlayersUnit: true,
              ),
              _ForgottenFavoritesSection(entries: summary.forgottenFavorites),
            ],
          );
        },
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.summary});

  final PlayAnalyticsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 3 : 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: t.t('play_analytics.totalSessions'),
          value: '${summary.totalSessions}',
          note: t.t('dashboard.qualityCount', {
            'included': summary.totalSessions,
            'excluded': 0,
          }),
        ),
        _StatCard(
          label: t.t('play_analytics.actualPlayingTime'),
          value: _minutesOrDash(
            summary.actualPlayingTime.average,
            t.t('collection.minutesUnit'),
          ),
          note: t.t('dashboard.qualityCount', {
            'included': summary.actualPlayingTime.includedCount,
            'excluded': summary.actualPlayingTime.excludedCount,
          }),
        ),
        _StatCard(
          label: t.t('play_analytics.actualVsNominal'),
          value: _signedMinutesOrDash(
            summary.actualVsNominalPlayingTime.average,
            t.t('collection.minutesUnit'),
          ),
          note: t.t('dashboard.qualityCount', {
            'included': summary.actualVsNominalPlayingTime.includedCount,
            'excluded': summary.actualVsNominalPlayingTime.excludedCount,
          }),
        ),
      ],
    );
  }
}

class _RatedSection extends ConsumerWidget {
  const _RatedSection({
    required this.title,
    required this.entries,
    this.appendPlayersUnit = false,
  });

  final String title;
  final List<RatedEntry> entries;
  final bool appendPlayersUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(t.t('dashboard.noData'))
            else
              for (final entry in entries)
                _RatedRow(entry: entry, appendPlayersUnit: appendPlayersUnit),
          ],
        ),
      ),
    );
  }
}

class _RatedRow extends ConsumerWidget {
  const _RatedRow({required this.entry, required this.appendPlayersUnit});

  final RatedEntry entry;
  final bool appendPlayersUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final fraction = (entry.average / 10).clamp(0.0, 1.0);
    final label = appendPlayersUnit
        ? '${entry.label}${t.t('collection.playersUnit')}'
        : entry.label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  widthFactor: fraction,
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
            width: 92,
            child: Text(
              t.t('play_analytics.ratingUnit', {
                'average': entry.average.toStringAsFixed(2),
                'count': entry.count,
              }),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgottenFavoritesSection extends ConsumerWidget {
  const _ForgottenFavoritesSection({required this.entries});

  final List<FavoriteEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('play_analytics.forgottenFavorites'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(t.t('dashboard.noData'))
            else
              for (final entry in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${t.t('collection.lastPlayedLabel', {'date': entry.lastPlayedDate})} / ${t.t('play_analytics.ratingUnit', {'average': entry.averageRating.toStringAsFixed(2), 'count': 1})}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GameDetailPage(gameKey: entry.gameKey),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

String _minutesOrDash(double? value, String unit) {
  return value == null ? '-' : '${value.round()}$unit';
}

String _signedMinutesOrDash(double? value, String unit) {
  if (value == null) {
    return '-';
  }
  final rounded = value.round();
  final sign = rounded > 0 ? '+' : '';
  return '$sign$rounded$unit';
}
