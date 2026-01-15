import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/manga.dart';
import '../services/manga_api_service.dart';
import '../services/isbn_lookup_service.dart';
import 'isbn_scanner_screen.dart';

class MangaEditScreen extends ConsumerStatefulWidget {
  final Manga manga;

  const MangaEditScreen({super.key, required this.manga});

  @override
  ConsumerState<MangaEditScreen> createState() => _MangaEditScreenState();
}

class _MangaEditScreenState extends ConsumerState<MangaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = MangaApiService();
  final _isbnLookupService = IsbnLookupService();

  // Form controllers
  late final TextEditingController _titelController;
  late final TextEditingController _bandController;
  late final TextEditingController _genreController;
  late final TextEditingController _autorController;
  late final TextEditingController _verlagController;
  late final TextEditingController _isbnController;
  late final TextEditingController _spracheController;
  late final TextEditingController _coverImageController;

  // Boolean fields
  late bool _read;
  late bool _double;
  late bool _newbuy;

  bool _isLoading = false;
  bool _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _titelController = TextEditingController(text: widget.manga.titel);
    _bandController = TextEditingController(text: widget.manga.band ?? '');
    _genreController = TextEditingController(text: widget.manga.genre ?? '');
    _autorController = TextEditingController(text: widget.manga.autor ?? '');
    _verlagController = TextEditingController(text: widget.manga.verlag ?? '');
    _isbnController = TextEditingController(text: widget.manga.isbn ?? '');
    _spracheController = TextEditingController(text: widget.manga.sprache ?? '');
    _coverImageController = TextEditingController(text: widget.manga.coverImage ?? '');

    _read = widget.manga.read;
    _double = widget.manga.double;
    _newbuy = widget.manga.newbuy;
  }

  @override
  void dispose() {
    _titelController.dispose();
    _bandController.dispose();
    _genreController.dispose();
    _autorController.dispose();
    _verlagController.dispose();
    _isbnController.dispose();
    _spracheController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

  Future<void> _lookupIsbn() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte ISBN eingeben')),
      );
      return;
    }

    setState(() {
      _isLookingUp = true;
    });

    try {
      final bookInfo = await _isbnLookupService.lookupByIsbn(isbn);

      if (bookInfo != null) {
        setState(() {
          // Only fill empty fields
          if (_titelController.text.isEmpty) {
            _titelController.text = bookInfo.title;
          }
          if (_autorController.text.isEmpty && bookInfo.authors != null) {
            _autorController.text = bookInfo.authors!;
          }
          if (_verlagController.text.isEmpty && bookInfo.publisher != null) {
            _verlagController.text = bookInfo.publisher!;
          }
          if (_spracheController.text.isEmpty && bookInfo.language != null) {
            _spracheController.text = bookInfo.language!;
          }
          if (_genreController.text.isEmpty && bookInfo.categories != null) {
            _genreController.text = bookInfo.categories!;
          }
          if (_coverImageController.text.isEmpty && bookInfo.coverImage != null) {
            _coverImageController.text = bookInfo.coverImage!;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informationen erfolgreich abgerufen!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keine Informationen für diese ISBN gefunden'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abrufen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
        });
      }
    }
  }

  Future<void> _updateManga() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updates = {
        'titel': _titelController.text.trim(),
        'band': _bandController.text.trim().isEmpty ? null : _bandController.text.trim(),
        'genre': _genreController.text.trim().isEmpty ? null : _genreController.text.trim(),
        'autor': _autorController.text.trim().isEmpty ? null : _autorController.text.trim(),
        'verlag': _verlagController.text.trim().isEmpty ? null : _verlagController.text.trim(),
        'isbn': _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        'sprache': _spracheController.text.trim().isEmpty ? null : _spracheController.text.trim(),
        'cover_image': _coverImageController.text.trim().isEmpty ? null : _coverImageController.text.trim(),
        'read': _read,
        'double': _double,
        'newbuy': _newbuy,
      };

      await _apiService.updateManga(widget.manga.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manga erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga bearbeiten'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateManga,
              tooltip: 'Speichern',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titel (Required)
            TextFormField(
              controller: _titelController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Titel eingeben';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Band
            TextFormField(
              controller: _bandController,
              decoration: const InputDecoration(
                labelText: 'Band',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                hintText: 'z.B. 1, 1-3, Special',
              ),
            ),
            const SizedBox(height: 16),

            // Genre
            TextFormField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: 'Genre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                hintText: 'z.B. Action, Romance, Sci-Fi',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Autor
            TextFormField(
              controller: _autorController,
              decoration: const InputDecoration(
                labelText: 'Autor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Verlag
            TextFormField(
              controller: _verlagController,
              decoration: const InputDecoration(
                labelText: 'Verlag',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ISBN
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _isbnController,
                    decoration: const InputDecoration(
                      labelText: 'ISBN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async {
                    final isbn = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IsbnScannerScreen(),
                      ),
                    );
                    if (isbn != null) {
                      _isbnController.text = isbn;
                      // Auto-lookup after scanning
                      _lookupIsbn();
                    }
                  },
                  tooltip: 'ISBN scannen',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Auto-fill button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLookingUp ? null : _lookupIsbn,
                icon: _isLookingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLookingUp
                    ? 'Suche Informationen...'
                    : 'Informationen automatisch abrufen'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sprache
            TextFormField(
              controller: _spracheController,
              decoration: const InputDecoration(
                labelText: 'Sprache',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
                hintText: 'z.B. Deutsch, Englisch, Japanisch',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Cover Image URL
            TextFormField(
              controller: _coverImageController,
              decoration: InputDecoration(
                labelText: 'Cover Bild URL',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.image),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (image != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Foto aufgenommen: ${image.name}'),
                              action: SnackBarAction(
                                label: 'Info',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Hinweis'),
                                      content: const Text(
                                        'Das Bild wurde lokal gespeichert. '
                                        'Für die vollständige Synchronisation '
                                        'müsste es auf einen Server hochgeladen werden. '
                                        'Füge stattdessen eine URL ein.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                      tooltip: 'Foto aufnehmen',
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bild ausgewählt: ${image.name}'),
                              action: SnackBarAction(
                                label: 'Info',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Hinweis'),
                                      content: const Text(
                                        'Das Bild wurde lokal gespeichert. '
                                        'Für die vollständige Synchronisation '
                                        'müsste es auf einen Server hochgeladen werden. '
                                        'Füge stattdessen eine URL ein.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                      tooltip: 'Aus Galerie wählen',
                    ),
                  ],
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Boolean switches
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Gelesen'),
                      subtitle: const Text('Habe ich diesen Manga schon gelesen?'),
                      value: _read,
                      onChanged: (value) {
                        setState(() {
                          _read = value;
                        });
                      },
                      secondary: const Icon(Icons.check_circle),
                    ),
                    SwitchListTile(
                      title: const Text('Doppelt'),
                      subtitle: const Text('Besitze ich diesen Manga mehrfach?'),
                      value: _double,
                      onChanged: (value) {
                        setState(() {
                          _double = value;
                        });
                      },
                      secondary: const Icon(Icons.content_copy),
                    ),
                    SwitchListTile(
                      title: const Text('Neu kaufen'),
                      subtitle: const Text('Möchte ich diesen Manga kaufen?'),
                      value: _newbuy,
                      onChanged: (value) {
                        setState(() {
                          _newbuy = value;
                        });
                      },
                      secondary: const Icon(Icons.shopping_cart),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Update button
            FilledButton.icon(
              onPressed: _isLoading ? null : _updateManga,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Aktualisiere...' : 'Änderungen speichern'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
