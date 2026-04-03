import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/manga.dart';
import '../providers/manga_providers.dart';
import '../widgets/detail_card.dart';
import 'manga_edit_screen.dart';

class MangaDetailScreen extends ConsumerWidget {
  final Manga manga;

  const MangaDetailScreen({super.key, required this.manga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Cover
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                manga.titel,
                style: const TextStyle(
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: manga.coverImage != null
                  ? Hero(
                      tag: 'manga-cover-${manga.id}',
                      child: Image.network(
                        manga.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.book, size: 100),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.book, size: 100),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (manga.read)
                        Chip(
                          avatar: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Gelesen'),
                          backgroundColor: Colors.green.withOpacity(0.2),
                        ),
                      if (manga.double)
                        Chip(
                          avatar: const Icon(Icons.content_copy, size: 18),
                          label: const Text('Duplikat'),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                        ),
                      if (manga.newbuy)
                        Chip(
                          avatar: const Icon(Icons.shopping_cart, size: 18),
                          label: const Text('Kaufen'),
                          backgroundColor: Colors.purple.withOpacity(0.2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details Section
                  DetailCard(
                    title: 'Informationen',
                    children: [
                      if (manga.band != null)
                        DetailRow(
                          icon: Icons.numbers,
                          label: 'Band',
                          value: manga.band!,
                        ),
                      if (manga.autor != null)
                        DetailRow(
                          icon: Icons.person,
                          label: 'Autor',
                          value: manga.autor!,
                        ),
                      if (manga.genre != null)
                        DetailRow(
                          icon: Icons.category,
                          label: 'Genre',
                          value: manga.genre!,
                        ),
                      if (manga.verlag != null)
                        DetailRow(
                          icon: Icons.business,
                          label: 'Verlag',
                          value: manga.verlag!,
                        ),
                      if (manga.sprache != null)
                        DetailRow(
                          icon: Icons.language,
                          label: 'Sprache',
                          value: manga.sprache!,
                        ),
                      if (manga.isbn != null)
                        DetailRow(
                          icon: Icons.qr_code,
                          label: 'ISBN',
                          value: manga.isbn!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Timestamps
                  if (manga.createdAt != null || manga.updatedAt != null)
                    DetailCard(
                      title: 'Zeitstempel',
                      children: [
                        if (manga.createdAt != null)
                          DetailRow(
                            icon: Icons.add_circle_outline,
                            label: 'Erstellt',
                            value: dateFormat.format(manga.createdAt!),
                          ),
                        if (manga.updatedAt != null)
                          DetailRow(
                            icon: Icons.update,
                            label: 'Zuletzt aktualisiert',
                            value: dateFormat.format(manga.updatedAt!),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: Icon(
                              manga.read ? Icons.remove_circle_outline : Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: Text(
                              manga.read ? 'Als ungelesen markieren' : 'Als gelesen markieren',
                            ),
                            onTap: () async {
                              try {
                                final apiService = ref.read(mangaApiProvider);
                                await apiService.updateManga(manga.id, {'read': !manga.read});
                                ref.invalidate(mangaListProvider);
                                ref.invalidate(statsProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Status aktualisiert')),
                                  );
                                  Navigator.pop(context);
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
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text(
                              'Manga löschen',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () => _showDeleteConfirmation(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => MangaEditScreen(manga: manga),
            ),
          );
          if (result == true) {
            ref.invalidate(mangaListProvider);
            ref.invalidate(statsProvider);
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text('Bearbeiten'),
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
              Navigator.pop(context); // Close dialog
              try {
                final apiService = ref.read(mangaApiProvider);
                await apiService.deleteManga(manga.id);
                ref.invalidate(mangaListProvider);
                ref.invalidate(statsProvider);
                if (context.mounted) {
                  Navigator.pop(context); // Close detail screen
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

