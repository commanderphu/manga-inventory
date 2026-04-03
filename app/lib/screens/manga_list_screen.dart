import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../providers/manga_providers.dart';
import '../widgets/manga_list_tile.dart';
import '../widgets/stat_card.dart';
import '../widgets/pagination_widget.dart';
import '../widgets/offline_banner.dart';
import 'manga_add_screen.dart';

class MangaListScreen extends ConsumerStatefulWidget {
  const MangaListScreen({super.key});

  @override
  ConsumerState<MangaListScreen> createState() => _MangaListScreenState();
}

class _MangaListScreenState extends ConsumerState<MangaListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(genreFilterProvider.notifier).state = null;
    ref.read(autorFilterProvider.notifier).state = null;
    ref.read(verlagFilterProvider.notifier).state = null;
    ref.read(spracheFilterProvider.notifier).state = null;
    ref.read(readFilterProvider.notifier).state = null;
    ref.read(doubleFilterProvider.notifier).state = null;
    ref.read(newbuyFilterProvider.notifier).state = null;
    ref.read(currentPageProvider.notifier).state = 1;
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mangaListAsync = ref.watch(mangaListProvider);
    final statsAsync = ref.watch(statsProvider);
    final hasActiveFilters = ref.watch(searchQueryProvider).isNotEmpty ||
        ref.watch(genreFilterProvider) != null ||
        ref.watch(autorFilterProvider) != null ||
        ref.watch(verlagFilterProvider) != null ||
        ref.watch(spracheFilterProvider) != null ||
        ref.watch(readFilterProvider) != null ||
        ref.watch(doubleFilterProvider) != null ||
        ref.watch(newbuyFilterProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Manga suchen...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              )
            : const Text('📚 Manga Sammlung'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(mangaListProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(mangaListProvider);
                ref.invalidate(statsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // Stats Section
                  SliverToBoxAdapter(
                    child: statsAsync.when(
                      data: (stats) => StatsSection(stats: stats),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ),

                  // Manga List
                  mangaListAsync.when(
                    data: (response) {
                      if (response.data.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Text('Keine Manga gefunden'),
                          ),
                        );
                      }
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final manga = response.data[index];
                                return MangaListTile(manga: manga);
                              },
                              childCount: response.data.length,
                            ),
                          ),
                          // Pagination
                          SliverToBoxAdapter(
                            child: PaginationWidget(
                                pagination: response.pagination),
                          ),
                        ],
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Fehler: $err'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.refresh(mangaListProvider),
                              child: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const MangaAddScreen()),
          );
          if (result == true) {
            // Refresh list after adding
            ref.invalidate(mangaListProvider);
            ref.invalidate(statsProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _clearAllFilters();
                    },
                    child: const Text('Zurücksetzen'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fertig'),
                  ),
                ],
              ),
            ),
            // Filter content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Genre Filter
                  _FilterTextField(
                    label: 'Genre',
                    icon: Icons.category,
                    provider: genreFilterProvider,
                  ),
                  const SizedBox(height: 16),

                  // Autor Filter
                  _FilterTextField(
                    label: 'Autor',
                    icon: Icons.person,
                    provider: autorFilterProvider,
                  ),
                  const SizedBox(height: 16),

                  // Verlag Filter
                  _FilterTextField(
                    label: 'Verlag',
                    icon: Icons.business,
                    provider: verlagFilterProvider,
                  ),
                  const SizedBox(height: 16),

                  // Sprache Filter
                  _FilterTextField(
                    label: 'Sprache',
                    icon: Icons.language,
                    provider: spracheFilterProvider,
                  ),
                  const SizedBox(height: 24),

                  // Boolean filters
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _BooleanFilterChip(
                    label: 'Gelesen',
                    icon: Icons.check_circle,
                    provider: readFilterProvider,
                  ),
                  const SizedBox(height: 8),

                  _BooleanFilterChip(
                    label: 'Duplikat',
                    icon: Icons.content_copy,
                    provider: doubleFilterProvider,
                  ),
                  const SizedBox(height: 8),

                  _BooleanFilterChip(
                    label: 'Kaufen',
                    icon: Icons.shopping_cart,
                    provider: newbuyFilterProvider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTextField extends ConsumerStatefulWidget {
  final String label;
  final IconData icon;
  final StateProvider<String?> provider;

  const _FilterTextField({
    required this.label,
    required this.icon,
    required this.provider,
  });

  @override
  ConsumerState<_FilterTextField> createState() => _FilterTextFieldState();
}

class _FilterTextFieldState extends ConsumerState<_FilterTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(widget.provider) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(widget.icon),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  ref.read(widget.provider.notifier).state = null;
                },
              )
            : null,
      ),
      onChanged: (value) {
        ref.read(widget.provider.notifier).state =
            value.isEmpty ? null : value;
      },
    );
  }
}

class _BooleanFilterChip extends ConsumerWidget {
  final String label;
  final IconData icon;
  final StateProvider<bool?> provider;

  const _BooleanFilterChip({
    required this.label,
    required this.icon,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);

    return Row(
      children: [
        Expanded(
          child: Text(label),
        ),
        SegmentedButton<bool?>(
          segments: const [
            ButtonSegment(
              value: null,
              label: Text('Alle'),
            ),
            ButtonSegment(
              value: true,
              label: Text('Ja'),
            ),
            ButtonSegment(
              value: false,
              label: Text('Nein'),
            ),
          ],
          selected: {value},
          onSelectionChanged: (Set<bool?> newSelection) {
            ref.read(provider.notifier).state = newSelection.first;
          },
        ),
      ],
    );
  }
}

