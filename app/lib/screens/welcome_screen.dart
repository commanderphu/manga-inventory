import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_title.dart';

/// Einmaliger Willkommens-Screen vor dem ersten Login.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/onboard.webp', height: 220),
                const SizedBox(height: 24),
                const BrandTitle(),
                const SizedBox(height: 8),
                Text(
                  'Deine Sammlung. Immer im Blick.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: BrandColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const _Feature(
                  icon: Icons.qr_code_scanner,
                  color: BrandColors.neonCyan,
                  text: 'ISBN scannen — Titel, Autor und Verlag kommen automatisch',
                ),
                const _Feature(
                  icon: Icons.check_circle,
                  color: BrandColors.read,
                  text: 'Sehen, was gelesen ist und was doppelt im Regal steht',
                ),
                const _Feature(
                  icon: Icons.shopping_cart,
                  color: BrandColors.wishlist,
                  text: 'Kaufliste fürs nächste Mal im Laden',
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => markOnboardingSeen(ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.coralPink,
                    foregroundColor: BrandColors.deepNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Los geht's"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Feature({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
