import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/repo/collection_repository.dart';
import '../../domain/play_audience.dart';
import 'bgg_import_page.dart';
import 'dashboard_page.dart';
import 'export_page.dart';
import 'game_detail_page.dart';
import 'local_game_form_page.dart';
import 'play_analytics_page.dart';
import 'photo_recognition_page.dart';
import 'scan_page.dart';
import 'search_registration_page.dart';
import 'settings_page.dart';
import 'shelf_recognition_page.dart';

class CollectionListPage extends ConsumerStatefulWidget {
  const CollectionListPage({super.key});

  @override
  ConsumerState<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends ConsumerState<CollectionListPage> {
  final _searchController = TextEditingController();
  final _expandedGameKeys = <String>{};
  bool _grid = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyQuery(String value) {
    final current = ref.read(collectionFilterProvider);
    ref.read(collectionFilterProvider.notifier).state = CollectionFilter(
      titleQuery: value,
      playerCount: current.playerCount,
      maxPlayingTime: current.maxPlayingTime,
      localOnly: current.localOnly,
      mechanics: current.mechanics,
      designers: current.designers,
      hasExpansionsOnly: current.hasExpansionsOnly,
      unplayedOnly: current.unplayedOnly,
      playAudience: current.playAudience,
    );
  }

  Future<void> _openAndRefresh(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    ref.invalidate(collectionListProvider);
    ref.invalidate(collectionFacetsProvider);
  }

  void _showAddMenu() {
    final t = ref.read(i18nProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(t.t('collection.addBgg')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAndRefresh(const SearchRegistrationPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: Text(t.t('collection.addBggImport')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAndRefresh(const BggImportPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(t.t('collection.addManual')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAndRefresh(const LocalGameFormPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(t.t('collection.addScan')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAndRefresh(const ScanPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(t.t('collection.addPhoto')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAndRefresh(const PhotoRecognitionPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_module_outlined),
                title: Text(t.t('collection.addShelf')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAndRefresh(const ShelfRecognitionPage());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final filter = ref.watch(collectionFilterProvider);
    final listAsync = ref.watch(collectionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('collection.title')),
        actions: [
          IconButton(
            tooltip: _grid
                ? t.t('collection.listView')
                : t.t('collection.gridView'),
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          IconButton(
            tooltip: t.t('nav.dashboard'),
            icon: const Icon(Icons.insights),
            onPressed: () => _openAndRefresh(const DashboardPage()),
          ),
          IconButton(
            tooltip: t.t('nav.playAnalytics'),
            icon: const Icon(Icons.query_stats),
            onPressed: () => _openAndRefresh(const PlayAnalyticsPage()),
          ),
          IconButton(
            tooltip: t.t('nav.export'),
            icon: const Icon(Icons.ios_share),
            onPressed: () => _openAndRefresh(const ExportPage()),
          ),
          IconButton(
            tooltip: t.t('nav.settings'),
            icon: const Icon(Icons.settings),
            onPressed: () => _openAndRefresh(const SettingsPage()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        icon: const Icon(Icons.add),
        label: Text(t.t('collection.add')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _applyQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: t.t('collection.searchHint'),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyQuery('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          _FilterBar(filter: filter),
          const Divider(height: 1),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$error'),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(t.t('collection.empty')));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(collectionListProvider),
                  child: _grid
                      ? _CollectionGrid(
                          items: items,
                          expandedGameKeys: _expandedGameKeys,
                          onTap: _openDetail,
                          onToggleExpanded: _toggleExpanded,
                        )
                      : _CollectionList(
                          items: items,
                          expandedGameKeys: _expandedGameKeys,
                          onTap: _openDetail,
                          onToggleExpanded: _toggleExpanded,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(CollectionListItem item) {
    _openAndRefresh(GameDetailPage(gameKey: item.game.gameKey));
  }

  void _toggleExpanded(CollectionListItem item) {
    setState(() {
      final key = item.game.gameKey;
      if (!_expandedGameKeys.add(key)) {
        _expandedGameKeys.remove(key);
      }
    });
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});

  final CollectionFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final sortOrder = ref.watch(collectionSortOrderProvider);
    final filter = ref.watch(collectionFilterProvider);

    void update({
      int? playerCount,
      int? maxPlayingTime,
      bool? localOnly,
      List<String>? mechanics,
      List<String>? designers,
      bool? hasExpansionsOnly,
      bool? unplayedOnly,
      PlayAudience? playAudience,
      bool clearPlayAudience = false,
      bool clearPlayers = false,
      bool clearTime = false,
    }) {
      ref.read(collectionFilterProvider.notifier).state = CollectionFilter(
        titleQuery: filter.titleQuery,
        playerCount: clearPlayers ? null : (playerCount ?? filter.playerCount),
        maxPlayingTime: clearTime
            ? null
            : (maxPlayingTime ?? filter.maxPlayingTime),
        localOnly: localOnly ?? filter.localOnly,
        mechanics: mechanics ?? filter.mechanics,
        designers: designers ?? filter.designers,
        hasExpansionsOnly: hasExpansionsOnly ?? filter.hasExpansionsOnly,
        unplayedOnly: unplayedOnly ?? filter.unplayedOnly,
        playAudience: clearPlayAudience
            ? null
            : (playAudience ?? filter.playAudience),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Tooltip(
            message: t.t('collection.filterLocalOnlyTooltip'),
            child: FilterChip(
              label: Text(t.t('collection.filterLocalOnly')),
              selected: filter.localOnly,
              onSelected: (value) => update(localOnly: value),
            ),
          ),
          const SizedBox(width: 8),
          _SortChip(value: sortOrder),
          const SizedBox(width: 8),
          _MultiSelectChip(
            label: t.t('collection.filterMechanics'),
            values: filter.mechanics,
            facets: ref.watch(collectionFacetsProvider).valueOrNull?.mechanics,
            onChanged: (values) => update(mechanics: values),
          ),
          const SizedBox(width: 8),
          _MultiSelectChip(
            label: t.t('collection.filterDesigners'),
            values: filter.designers,
            facets: ref.watch(collectionFacetsProvider).valueOrNull?.designers,
            onChanged: (values) => update(designers: values),
          ),
          const SizedBox(width: 8),
          _DropdownChip<PlayAudience>(
            label: t.t('collection.filterPlayAudience'),
            value: filter.playAudience,
            options: PlayAudience.values,
            optionLabel: (value) => t.t('play_audience.${value.name}'),
            onChanged: (value) => value == null
                ? update(clearPlayAudience: true)
                : update(playAudience: value),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(t.t('collection.filterHasExpansions')),
            selected: filter.hasExpansionsOnly,
            onSelected: (value) => update(hasExpansionsOnly: value),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(t.t('collection.filterUnplayed')),
            selected: filter.unplayedOnly,
            onSelected: (value) => update(unplayedOnly: value),
          ),
          const SizedBox(width: 8),
          _DropdownChip<int>(
            label: t.t('collection.filterPlayerCount'),
            value: filter.playerCount,
            options: const [1, 2, 3, 4, 5, 6, 7, 8],
            optionLabel: (value) => '$value${t.t('collection.playersUnit')}',
            onChanged: (value) => value == null
                ? update(clearPlayers: true)
                : update(playerCount: value),
          ),
          const SizedBox(width: 8),
          _DropdownChip<int>(
            label: t.t('collection.filterMaxTime'),
            value: filter.maxPlayingTime,
            options: const [30, 60, 90, 120, 180],
            optionLabel: (value) => '≤$value${t.t('collection.minutesUnit')}',
            onChanged: (value) => value == null
                ? update(clearTime: true)
                : update(maxPlayingTime: value),
          ),
        ],
      ),
    );
  }
}

class _DropdownChip<T> extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T?>(
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem<T?>(value: null, child: Text('—')),
        for (final option in options)
          PopupMenuItem<T?>(value: option, child: Text(optionLabel(option))),
      ],
      child: Chip(
        label: Text(value == null ? label : optionLabel(value as T)),
        backgroundColor: value == null
            ? null
            : Theme.of(context).colorScheme.secondaryContainer,
        avatar: const Icon(Icons.arrow_drop_down, size: 18),
        onDeleted: value == null ? null : () => onChanged(null),
        deleteIcon: const Icon(Icons.close, size: 18),
      ),
    );
  }
}

class _MultiSelectChip extends ConsumerWidget {
  const _MultiSelectChip({
    required this.label,
    required this.values,
    required this.facets,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final List<String>? facets;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = facets ?? const <String>[];
    final selected = values.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: const Icon(Icons.arrow_drop_down, size: 18),
      label: Text(selected ? '$label (${values.length})' : label),
      backgroundColor: selected ? colorScheme.secondaryContainer : null,
      onPressed: options.isEmpty
          ? null
          : () async {
              final result = await showDialog<Set<String>>(
                context: context,
                builder: (_) => _MultiSelectFilterDialog(
                  title: label,
                  options: options,
                  initialSelection: values.toSet(),
                ),
              );
              if (result != null) {
                onChanged(result.toList()..sort());
              }
            },
    );
  }
}

class _MultiSelectFilterDialog extends StatefulWidget {
  const _MultiSelectFilterDialog({
    required this.title,
    required this.options,
    required this.initialSelection,
  });

  final String title;
  final List<String> options;
  final Set<String> initialSelection;

  @override
  State<_MultiSelectFilterDialog> createState() =>
      _MultiSelectFilterDialogState();
}

class _MultiSelectFilterDialogState extends State<_MultiSelectFilterDialog> {
  late final TextEditingController _query;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
    _selected = {...widget.initialSelection};
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final i18n = ref.watch(i18nProvider);
        final query = _query.text.trim().toLowerCase();
        final visible = widget.options
            .where((option) => option.toLowerCase().contains(query))
            .toList();
        return AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _query,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: i18n.t('collection.filterDialogSearchHint'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final option = visible[index];
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(option),
                        value: _selected.contains(option),
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selected.add(option);
                            } else {
                              _selected.remove(option);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() => _selected.clear()),
              child: Text(i18n.t('collection.filterDialogClear')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(i18n.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: Text(i18n.t('collection.filterDialogApply')),
            ),
          ],
        );
      },
    );
  }
}

class _SortChip extends ConsumerWidget {
  const _SortChip({required this.value});

  final CollectionSortOrder value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);

    String label(CollectionSortOrder order) {
      return switch (order) {
        CollectionSortOrder.name => t.t('collection.sortByName'),
        CollectionSortOrder.designer => t.t('collection.sortByDesigner'),
        CollectionSortOrder.lastPlayed => t.t('collection.sortByLastPlayed'),
      };
    }

    return PopupMenuButton<CollectionSortOrder>(
      onSelected: (order) {
        ref.read(collectionSortOrderProvider.notifier).state = order;
      },
      itemBuilder: (context) => [
        for (final order in CollectionSortOrder.values)
          PopupMenuItem<CollectionSortOrder>(
            value: order,
            child: Text(label(order)),
          ),
      ],
      child: Chip(
        label: Text(label(value)),
        backgroundColor: value == CollectionSortOrder.name
            ? null
            : Theme.of(context).colorScheme.secondaryContainer,
        avatar: const Icon(Icons.sort_by_alpha, size: 18),
      ),
    );
  }
}

class _CollectionList extends ConsumerWidget {
  const _CollectionList({
    required this.items,
    required this.expandedGameKeys,
    required this.onTap,
    required this.onToggleExpanded,
  });

  final List<CollectionListItem> items;
  final Set<String> expandedGameKeys;
  final void Function(CollectionListItem) onTap;
  final void Function(CollectionListItem) onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = groupCollectionItems(items);
    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final group = groups[index];
        final isExpanded = expandedGameKeys.contains(group.parent.game.gameKey);
        return Column(
          children: [
            _CollectionListTile(
              item: group.parent,
              onTap: onTap,
              expansionCount: group.expansions.length,
              isExpanded: isExpanded,
              onToggleExpanded: group.expansions.isEmpty
                  ? null
                  : () => onToggleExpanded(group.parent),
              isOrphanExpansion: group.isOrphanExpansion,
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  for (final expansion in group.expansions)
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: _CollectionListTile(
                        item: expansion,
                        onTap: onTap,
                        showExpansionBadge: true,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CollectionListTile extends StatelessWidget {
  const _CollectionListTile({
    required this.item,
    required this.onTap,
    this.showExpansionBadge = false,
    this.isOrphanExpansion = false,
    this.expansionCount = 0,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  final CollectionListItem item;
  final void Function(CollectionListItem) onTap;
  final bool showExpansionBadge;
  final bool isOrphanExpansion;
  final int expansionCount;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _Thumbnail(url: item.game.thumbnailUrl),
      title: Text(
        item.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _Subtitle(item: item),
      trailing: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (expansionCount > 0)
            _TextBadge(
              labelKey: 'collection.expansionCount',
              args: {'count': expansionCount},
            ),
          if (showExpansionBadge ||
              item.game.gameKind == AppConstants.gameKindExpansion)
            const _TextBadge(labelKey: 'collection.expansionBadge'),
          if (isOrphanExpansion)
            const _TextBadge(labelKey: 'collection.parentUnregistered'),
          if (item.isLocal) const _TextBadge(labelKey: 'collection.localBadge'),
          if (!item.isLocal && item.bestPlayersBadge != null)
            Text(item.bestPlayersBadge!),
          if (onToggleExpanded != null)
            IconButton(
              tooltip: _ExpansionToggleTooltip.of(context, isExpanded),
              icon: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.expand_more),
              ),
              onPressed: onToggleExpanded,
            ),
        ],
      ),
      onTap: () => onTap(item),
    );
  }
}

class _CollectionGrid extends ConsumerWidget {
  const _CollectionGrid({
    required this.items,
    required this.expandedGameKeys,
    required this.onTap,
    required this.onToggleExpanded,
  });

  final List<CollectionListItem> items;
  final Set<String> expandedGameKeys;
  final void Function(CollectionListItem) onTap;
  final void Function(CollectionListItem) onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = groupCollectionItems(items);
    final visibleItems = <_GridEntry>[
      for (final group in groups) ...[
        _GridEntry(
          item: group.parent,
          expansionCount: group.expansions.length,
          isExpanded: expandedGameKeys.contains(group.parent.game.gameKey),
          canToggle: group.expansions.isNotEmpty,
        ),
        if (expandedGameKeys.contains(group.parent.game.gameKey))
          for (final expansion in group.expansions)
            _GridEntry(item: expansion, showExpansionBadge: true),
      ],
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.72,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final entry = visibleItems[index];
        final item = entry.item;
        return InkWell(
          onTap: () => onTap(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _Thumbnail(url: item.game.thumbnailUrl, size: 120),
                    ),
                    if (item.isLocal)
                      const Positioned(
                        top: 4,
                        left: 4,
                        child: _TextBadge(labelKey: 'collection.localBadge'),
                      ),
                    if (entry.showExpansionBadge ||
                        item.game.gameKind == AppConstants.gameKindExpansion)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: _TextBadge(
                          labelKey: 'collection.expansionBadge',
                        ),
                      ),
                    if (entry.expansionCount > 0)
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: _TextBadge(
                          labelKey: 'collection.expansionCount',
                          args: {'count': entry.expansionCount},
                        ),
                      ),
                    if (entry.canToggle)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: IconButton.filledTonal(
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: _ExpansionToggleTooltip.of(
                            context,
                            entry.isExpanded,
                          ),
                          icon: AnimatedRotation(
                            turns: entry.isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const Icon(Icons.expand_more),
                          ),
                          onPressed: () => onToggleExpanded(item),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Subtitle extends ConsumerWidget {
  const _Subtitle({required this.item});

  final CollectionListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final sortOrder = ref.watch(collectionSortOrderProvider);
    final filter = ref.watch(collectionFilterProvider);
    final parts = <String>[];
    final game = item.game;
    if (game.publisherMinPlayers != null && game.publisherMaxPlayers != null) {
      parts.add(
        '${game.publisherMinPlayers}–${game.publisherMaxPlayers}'
        '${t.t('collection.playersUnit')}',
      );
    }
    if (game.playingTime != null) {
      parts.add('${game.playingTime}${t.t('collection.minutesUnit')}');
    }
    if (game.weight != null) {
      parts.add(
        '${t.t('collection.weightShort')} ${game.weight!.toStringAsFixed(1)}',
      );
    }
    final meta = parts.join(' · ');
    final subtitle = item.subtitle;
    final showDesigners =
        sortOrder == CollectionSortOrder.designer && game.designers.isNotEmpty;
    final showPlayStatus =
        sortOrder == CollectionSortOrder.lastPlayed || filter.unplayedOnly;
    if (meta.isEmpty && subtitle == null && !showDesigners && !showPlayStatus) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.isNotEmpty)
          Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (showDesigners)
          Text(
            '${t.t('collection.designerLabel')}: ${game.designers.join('・')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (showPlayStatus)
          Text(
            item.playCount > 0 && item.lastPlayedDate != null
                ? t.t('collection.lastPlayedLabel', {
                    'date': item.lastPlayedDate,
                  })
                : t.t('collection.neverPlayedLabel'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, this.size = 44});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.casino, size: size * 0.5),
    );
    final source = url;
    if (source == null || source.isEmpty) {
      return placeholder;
    }
    return Image.network(
      source,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

class _TextBadge extends ConsumerWidget {
  const _TextBadge({required this.labelKey, this.args = const {}});

  final String labelKey;
  final Map<String, Object?> args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        t.t(labelKey, args),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _ExpansionToggleTooltip {
  const _ExpansionToggleTooltip._();

  static String of(BuildContext context, bool isExpanded) {
    final container = ProviderScope.containerOf(context, listen: false);
    final t = container.read(i18nProvider);
    return t.t(
      isExpanded
          ? 'collection.collapseExpansions'
          : 'collection.expandExpansions',
    );
  }
}

class _GridEntry {
  const _GridEntry({
    required this.item,
    this.expansionCount = 0,
    this.isExpanded = false,
    this.canToggle = false,
    this.showExpansionBadge = false,
  });

  final CollectionListItem item;
  final int expansionCount;
  final bool isExpanded;
  final bool canToggle;
  final bool showExpansionBadge;
}
