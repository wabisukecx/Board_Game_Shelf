import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/collection_analytics.dart';
import '../widgets/analytics_sections.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final summaryAsync = ref.watch(analyticsProvider);
    final includeNotOwned = ref.watch(analyticsIncludeNotOwnedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('dashboard.title'))),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$error'),
          ),
        ),
        data: (summary) {
          if (summary.totalCount == 0) {
            return Center(child: Text(t.t('dashboard.empty')));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(t.t('dashboard.ownedOnly')),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(t.t('dashboard.includeAll')),
                    icon: const Icon(Icons.all_inbox_outlined),
                  ),
                ],
                selected: {includeNotOwned},
                onSelectionChanged: (values) {
                  ref.read(analyticsIncludeNotOwnedProvider.notifier).state =
                      values.single;
                },
              ),
              const SizedBox(height: 16),
              _Overview(summary: summary),
              const SizedBox(height: 16),
              _QualityNotes(summary: summary),
              const SizedBox(height: 16),
              AnalyticsDistributionSection(
                title: t.t('dashboard.weightDistribution'),
                distribution: summary.weightDistribution,
              ),
              AnalyticsDistributionSection(
                title: t.t('dashboard.timeDistribution'),
                distribution: summary.playingTimeDistribution,
              ),
              AnalyticsDistributionSection(
                title: t.t('dashboard.playerCoverage'),
                distribution: summary.playerCoverage,
              ),
              AnalyticsDistributionSection(
                title: t.t('dashboard.decadeDistribution'),
                distribution: summary.decadeDistribution,
              ),
              AnalyticsDistributionSection(
                title: t.t('dashboard.ratingDistribution'),
                distribution: summary.ratingDistribution,
              ),
              AnalyticsDistributionSection(
                title: t.t('dashboard.strategicDepthDistribution'),
                distribution: summary.strategicDepthDistribution,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.learningCurveTypes'),
                entries: summary.learningCurveTypes,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.playerTypes'),
                entries: summary.playerTypes,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.masteryTimes'),
                entries: summary.masteryTimes,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.mechanicsTop'),
                entries: summary.mechanicsTop,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.categoriesTop'),
                entries: summary.categoriesTop,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.designersTop'),
                entries: summary.designersTop,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.publishersTop'),
                entries: summary.publishersTop,
              ),
              AnalyticsRankingSection(
                title: t.t('dashboard.storageLocations'),
                entries: summary.storageLocations,
              ),
              AnalyticsDistributionSection(
                title: t.t('dashboard.acquisitionsByMonth'),
                distribution: summary.acquisitionsByMonth,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.summary});

  final AnalyticsSummary summary;

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
          label: t.t('dashboard.total'),
          value: '${summary.totalCount}',
          note: t.t('dashboard.totalNote', {
            'owned': summary.ownedCount,
            'notOwned': summary.notOwnedCount,
          }),
        ),
        _StatCard(
          label: t.t('dashboard.localCount'),
          value: '${summary.localCount}',
          note: t.t('dashboard.bggCount', {'count': summary.bggCount}),
        ),
        _StatCard(
          label: t.t('dashboard.baseCount'),
          value: '${summary.baseCount}',
          note: t.t('dashboard.expansionCount', {
            'count': summary.expansionCount,
          }),
        ),
        _StatCard(
          label: t.t('dashboard.avgWeight'),
          value: _numberOrDash(summary.weight.average),
          note: _quality(
            t,
            summary.weight.includedCount,
            summary.weight.excludedCount,
          ),
        ),
        _StatCard(
          label: t.t('dashboard.avgRating'),
          value: _numberOrDash(summary.rating.average),
          note: _quality(
            t,
            summary.rating.includedCount,
            summary.rating.excludedCount,
          ),
        ),
        _StatCard(
          label: t.t('analysis.initialBarrier'),
          value: _numberOrDash(summary.initialBarrier.average),
          note: _quality(
            t,
            summary.initialBarrier.includedCount,
            summary.initialBarrier.excludedCount,
          ),
        ),
        _StatCard(
          label: t.t('analysis.strategicDepth'),
          value: _numberOrDash(summary.strategicDepth.average),
          note: _quality(
            t,
            summary.strategicDepth.includedCount,
            summary.strategicDepth.excludedCount,
          ),
        ),
        _StatCard(
          label: t.t('analysis.replayability'),
          value: _numberOrDash(summary.replayability.average),
          note: _quality(
            t,
            summary.replayability.includedCount,
            summary.replayability.excludedCount,
          ),
        ),
        _StatCard(
          label: t.t('dashboard.priceSum'),
          value: _money(summary.purchasePrice.sum),
          note: t.t('dashboard.priceAverage', {
            'value': _moneyOrDash(summary.purchasePrice.average),
            'included': summary.purchasePrice.includedCount,
            'excluded': summary.purchasePrice.excludedCount,
          }),
        ),
      ],
    );
  }
}

class _QualityNotes extends ConsumerWidget {
  const _QualityNotes({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('dashboard.qualityTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.t('dashboard.qualityBody', {
                'local': summary.localCount,
                'weightMissing': summary.weight.excludedCount,
                'ratingMissing': summary.rating.excludedCount,
                'priceMissing': summary.purchasePrice.excludedCount,
              }),
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

String _quality(dynamic t, int included, int excluded) {
  return t.t('dashboard.qualityCount', {
    'included': included,
    'excluded': excluded,
  });
}

String _numberOrDash(double? value) {
  return value == null ? '-' : value.toStringAsFixed(2);
}

String _money(double value) {
  return value.round().toString();
}

String _moneyOrDash(double? value) {
  return value == null ? '-' : _money(value);
}
