import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Current user provider
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  try {
    if (await authService.isLoggedIn()) {
      return await authService.getUser();
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Auth token provider
final authTokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getToken();
});

/// Is logged in provider
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isLoggedIn();
});

/// Auth state notifier for login/logout actions
class AuthNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  AuthNotifier(this.authService) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  final AuthService authService;

  Future<void> _loadUser() async {
    try {
      if (await authService.isLoggedIn()) {
        final user = await authService.getUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await authService.login(email, password);
      state = AsyncValue.data(result['user']);

      // Register device token for notifications
      try {
        final token = await authService.getToken();
        if (token != null) {
          final notificationService = NotificationService();
          await notificationService.registerToken(token);
          await notificationService.initialize();
        }
      } catch (e) {
        // Ignore notification errors - don't block login
        print('Failed to register notifications: $e');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> register(String email, String name, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await authService.register(email, name, password);
      state = AsyncValue.data(result['user']);

      // Register device token for notifications
      try {
        final token = await authService.getToken();
        if (token != null) {
          final notificationService = NotificationService();
          await notificationService.registerToken(token);
          await notificationService.initialize();
        }
      } catch (e) {
        // Ignore notification errors - don't block registration
        print('Failed to register notifications: $e');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    // Unregister device token
    try {
      final token = await authService.getToken();
      if (token != null) {
        final notificationService = NotificationService();
        await notificationService.unregisterToken(token);
      }
    } catch (e) {
      // Ignore errors during logout
      print('Failed to unregister notifications: $e');
    }

    await authService.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await authService.updateSettings(settings);
    // Reload user data
    await _loadUser();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
