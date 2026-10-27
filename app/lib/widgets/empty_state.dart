import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Leere Liste: entweder ist die Sammlung leer oder Suche/Filter treffen
/// nichts. Motiv aus dem Brand-Set (docs/BRAND_SETUP.md, "Empty State").
class EmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onAction;

  const EmptyState({super.key, required this.filtered, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/empty_state.webp',
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            filtered ? 'Nichts gefunden' : 'Deine Sammlung ist noch leer',
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Für diese Suche oder diese Filter gibt es keinen Treffer.'
                : 'Scanne die ISBN deines ersten Bandes oder trag ihn von Hand ein.',
            style: textTheme.bodyMedium?.copyWith(color: BrandColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (filtered)
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Filter zurücksetzen'),
            )
          else
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.coralPink,
                foregroundColor: BrandColors.deepNavy,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Ersten Manga hinzufügen'),
            ),
        ],
      ),
    );
  }
}
