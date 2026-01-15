import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Initialize notifications on app start
final notificationInitProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  await notificationService.initialize();
});
