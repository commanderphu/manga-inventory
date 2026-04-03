import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../providers/manga_providers.dart';

class PaginationWidget extends ConsumerWidget {
  final Pagination pagination;

  const PaginationWidget({super.key, required this.pagination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final totalPages = pagination.pages;

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: currentPage > 1
                    ? () => ref.read(currentPageProvider.notifier).state = 1
                    : null,
                tooltip: 'Erste Seite',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => ref.read(currentPageProvider.notifier).state = currentPage - 1
                    : null,
                tooltip: 'Vorherige Seite',
              ),
              ..._buildPageNumbers(context, ref, currentPage, totalPages),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => ref.read(currentPageProvider.notifier).state = currentPage + 1
                    : null,
                tooltip: 'Nächste Seite',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: currentPage < totalPages
                    ? () => ref.read(currentPageProvider.notifier).state = totalPages
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
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);

    if (currentPage <= 3) end = 5.clamp(1, totalPages);
    if (currentPage >= totalPages - 2) start = (totalPages - 4).clamp(1, totalPages);

    return [
      for (int i = start; i <= end; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: i == currentPage
              ? FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('$i'),
                )
              : OutlinedButton(
                  onPressed: () => ref.read(currentPageProvider.notifier).state = i,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('$i'),
                ),
        ),
    ];
  }
}
