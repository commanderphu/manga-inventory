import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Schriftzug laut docs/BRAND_SETUP.md: "MANGA" in Warm White,
/// "INVENTORY" in Coral.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(children: [
        TextSpan(
            text: 'MANGA ', style: TextStyle(color: BrandColors.warmWhite)),
        TextSpan(
            text: 'INVENTORY', style: TextStyle(color: BrandColors.coralPink)),
      ]),
      style: Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}
