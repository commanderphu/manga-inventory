import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

bool _isConnected(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Initial state
  final initial = await connectivity.checkConnectivity();
  final initialOnline = _isConnected(initial);
  SyncService.instance.setOnlineStatus(initialOnline);
  yield initialOnline;

  // Listen for changes
  await for (final results in connectivity.onConnectivityChanged) {
    final isOnline = _isConnected(results);
    SyncService.instance.setOnlineStatus(isOnline);
    yield isOnline;
  }
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
    data: (online) => online,
    orElse: () => true,
  );
});
