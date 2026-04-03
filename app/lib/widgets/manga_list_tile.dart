import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../providers/manga_providers.dart';
import '../screens/manga_detail_screen.dart';
import '../screens/manga_edit_screen.dart';

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
                    return _coverPlaceholder();
                  },
                ),
              )
            : _coverPlaceholder(),
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
        onLongPress: () => _showMangaOptions(context, ref),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.book, size: 24),
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
