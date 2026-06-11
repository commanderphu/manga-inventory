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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // |< erste Seite
          _NavButton(
            icon: Icons.first_page,
            onPressed: currentPage > 1
                ? () => ref.read(currentPageProvider.notifier).state = 1
                : null,
          ),
          // < vorherige Seite
          _NavButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 1
                ? () =>
                    ref.read(currentPageProvider.notifier).state = currentPage - 1
                : null,
          ),

          // Seitenzahlen mit Punkten als Trenner
          ..._buildPageItems(context, ref, currentPage, totalPages, colorScheme),

          // > nächste Seite
          _NavButton(
            icon: Icons.chevron_right,
            onPressed: currentPage < totalPages
                ? () =>
                    ref.read(currentPageProvider.notifier).state = currentPage + 1
                : null,
          ),
          // >| letzte Seite
          _NavButton(
            icon: Icons.last_page,
            onPressed: currentPage < totalPages
                ? () =>
                    ref.read(currentPageProvider.notifier).state = totalPages
                : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageItems(
    BuildContext context,
    WidgetRef ref,
    int currentPage,
    int totalPages,
    ColorScheme colorScheme,
  ) {
    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);
    if (currentPage <= 3) end = 5.clamp(1, totalPages);
    if (currentPage >= totalPages - 2) start = (totalPages - 4).clamp(1, totalPages);

    final pages = [for (int i = start; i <= end; i++) i];
    final items = <Widget>[];

    for (int idx = 0; idx < pages.length; idx++) {
      final page = pages[idx];
      final isActive = page == currentPage;

      items.add(
        GestureDetector(
          onTap: isActive
              ? null
              : () => ref.read(currentPageProvider.notifier).state = page,
          child: Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: isActive
                ? BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );

      // Trennpunkt zwischen Seitenzahlen
      if (idx < pages.length - 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '·',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
    }
    return items;
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: onPressed != null
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
    );
  }
}
