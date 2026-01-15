import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../services/manga_api_service.dart';
import '../providers/auth_provider.dart';
import 'manga_add_screen.dart';
import 'manga_edit_screen.dart';
import 'manga_detail_screen.dart';

// Provider for manga API service with auth token
final mangaApiProvider = Provider((ref) {
  final authToken = ref.watch(authTokenProvider).value;
  return MangaApiService(authToken: authToken);
});

// Search and filter state
final searchQueryProvider = StateProvider<String>((ref) => '');
final genreFilterProvider = StateProvider<String?>((ref) => null);
final autorFilterProvider = StateProvider<String?>((ref) => null);
final verlagFilterProvider = StateProvider<String?>((ref) => null);
final spracheFilterProvider = StateProvider<String?>((ref) => null);
final readFilterProvider = StateProvider<bool?>((ref) => null);
final doubleFilterProvider = StateProvider<bool?>((ref) => null);
final newbuyFilterProvider = StateProvider<bool?>((ref) => null);

// Pagination state
final currentPageProvider = StateProvider<int>((ref) => 1);
final itemsPerPageProvider = StateProvider<int>((ref) => 20);

// Provider for manga list with filters and pagination
final mangaListProvider = FutureProvider.autoDispose<MangaListResponse>((ref) async {
  final apiService = ref.watch(mangaApiProvider);
  final search = ref.watch(searchQueryProvider);
  final genre = ref.watch(genreFilterProvider);
  final autor = ref.watch(autorFilterProvider);
  final verlag = ref.watch(verlagFilterProvider);
  final sprache = ref.watch(spracheFilterProvider);
  final read = ref.watch(readFilterProvider);
  final double = ref.watch(doubleFilterProvider);
  final newbuy = ref.watch(newbuyFilterProvider);
  final page = ref.watch(currentPageProvider);
  final limit = ref.watch(itemsPerPageProvider);

  return await apiService.getMangas(
    page: page,
    limit: limit,
    search: search.isEmpty ? null : search,
    genre: genre,
    autor: autor,
    verlag: verlag,
    sprache: sprache,
    read: read,
    double: double,
    newbuy: newbuy,
  );
});

// Provider for stats
final statsProvider = FutureProvider.autoDispose<MangaStats>((ref) async {
  final apiService = ref.watch(mangaApiProvider);
  return await apiService.getStats();
});

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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mangaListProvider);
          ref.invalidate(statsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Stats Section
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _StatsSection(stats: stats),
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
                      child: _PaginationWidget(pagination: response.pagination),
                    ),
                  ],
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

class _StatsSection extends StatelessWidget {
  final MangaStats stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Gesamt',
              value: stats.total,
              icon: Icons.book,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Gelesen',
              value: stats.read,
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Duplikate',
              value: stats.duplicates,
              icon: Icons.content_copy,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Kaufen',
              value: stats.toBuy,
              icon: Icons.shopping_cart,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MangaListTile extends ConsumerWidget {
  final Manga manga;

  const MangaListTile({
    super.key,
    required this.manga,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: manga.coverImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  manga.coverImage!,
                  width: 40,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 40,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 24),
                    );
                  },
                ),
              )
            : Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.book, size: 24),
              ),
        title: Text(
          manga.titel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (manga.autor != null)
              Text(
                manga.autor!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (manga.read)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ),
                if (manga.double)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.content_copy, size: 16, color: Colors.orange),
                  ),
                if (manga.newbuy)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.shopping_cart, size: 16, color: Colors.purple),
                  ),
                if (manga.genre != null)
                  Expanded(
                    child: Text(
                      manga.genre!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: manga.band != null
            ? Chip(
                label: Text(
                  'Bd. ${manga.band}',
                  style: const TextStyle(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MangaDetailScreen(manga: manga),
            ),
          );
        },
        onLongPress: () {
          _showMangaOptions(context, ref);
        },
      ),
    );
  }

  void _showMangaOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Bearbeiten'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaEditScreen(manga: manga),
                ),
              );
              if (result == true) {
                ref.invalidate(mangaListProvider);
                ref.invalidate(statsProvider);
              }
            },
          ),
          ListTile(
            leading: Icon(
              manga.read ? Icons.remove_circle_outline : Icons.check_circle,
            ),
            title: Text(manga.read ? 'Als ungelesen markieren' : 'Als gelesen markieren'),
            onTap: () async {
              Navigator.pop(context);
              try {
                final apiService = ref.read(mangaApiProvider);
                await apiService.updateManga(manga.id, {'read': !manga.read});
                ref.invalidate(mangaListProvider);
                ref.invalidate(statsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status aktualisiert')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Löschen', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manga löschen?'),
        content: Text('Möchtest du "${manga.titel}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = ref.read(mangaApiProvider);
                await apiService.deleteManga(manga.id);
                ref.invalidate(mangaListProvider);
                ref.invalidate(statsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manga gelöscht')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              }
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PaginationWidget extends ConsumerWidget {
  final Pagination pagination;

  const _PaginationWidget({required this.pagination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final totalPages = pagination.pages;

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Page info
          Text(
            'Seite $currentPage von $totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${pagination.total} Manga insgesamt',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Pagination buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First page
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: currentPage > 1
                    ? () {
                        ref.read(currentPageProvider.notifier).state = 1;
                      }
                    : null,
                tooltip: 'Erste Seite',
              ),
              // Previous page
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () {
                        ref.read(currentPageProvider.notifier).state =
                            currentPage - 1;
                      }
                    : null,
                tooltip: 'Vorherige Seite',
              ),
              // Page numbers
              ..._buildPageNumbers(context, ref, currentPage, totalPages),
              // Next page
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () {
                        ref.read(currentPageProvider.notifier).state =
                            currentPage + 1;
                      }
                    : null,
                tooltip: 'Nächste Seite',
              ),
              // Last page
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: currentPage < totalPages
                    ? () {
                        ref.read(currentPageProvider.notifier).state =
                            totalPages;
                      }
                    : null,
                tooltip: 'Letzte Seite',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(
    BuildContext context,
    WidgetRef ref,
    int currentPage,
    int totalPages,
  ) {
    final List<Widget> pageButtons = [];

    // Show max 5 page buttons
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);

    // Adjust if at the beginning
    if (currentPage <= 3) {
      end = 5.clamp(1, totalPages);
    }

    // Adjust if at the end
    if (currentPage >= totalPages - 2) {
      start = (totalPages - 4).clamp(1, totalPages);
    }

    for (int i = start; i <= end; i++) {
      final isCurrentPage = i == currentPage;
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: isCurrentPage
              ? FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('$i'),
                )
              : OutlinedButton(
                  onPressed: () {
                    ref.read(currentPageProvider.notifier).state = i;
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('$i'),
                ),
        ),
      );
    }

    return pageButtons;
  }
}
