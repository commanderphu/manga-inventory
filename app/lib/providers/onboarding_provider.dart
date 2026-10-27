import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _seenKey = 'onboarding_seen';

/// Ob der Willkommens-Screen schon einmal mit "Los geht's" bestätigt wurde.
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  return await _storage.read(key: _seenKey) == 'true';
});

Future<void> markOnboardingSeen(WidgetRef ref) async {
  await _storage.write(key: _seenKey, value: 'true');
  ref.invalidate(onboardingSeenProvider);
}
