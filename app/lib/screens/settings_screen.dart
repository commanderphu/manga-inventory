import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Nicht angemeldet'));
          }

          final settings = user['settings'] ?? {};
          final theme = settings['theme'] ?? 'system';
          final notifications = settings['notifications'] ?? true;

          return ListView(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: user['avatar_url'] != null
                    ? ClipOval(
                        child: Image.network(
                          user['avatar_url'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                user['name'] ?? 'Unbekannt',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                user['email'] ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Design'),
                subtitle: Text(_getThemeLabel(theme)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showThemeDialog(context, ref, theme);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Benachrichtigungen'),
                subtitle: const Text('Über Aktivitäten informieren'),
                value: notifications,
                onChanged: (value) async {
                  try {
                    await ref.read(authNotifierProvider.notifier).updateSettings({
                      'theme': theme,
                      'notifications': value,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Einstellungen gespeichert')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fehler: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Abmelden',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Abmelden'),
                      content: const Text('Möchtest du dich wirklich abmelden?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Abbrechen'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Abmelden'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Hell';
      case 'dark':
        return 'Dunkel';
      case 'system':
      default:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, String currentTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Design wählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  _updateTheme(context, ref, value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Hell'),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  _updateTheme(context, ref, value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Dunkel'),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  _updateTheme(context, ref, value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateTheme(BuildContext context, WidgetRef ref, String theme) async {
    final authState = ref.read(authNotifierProvider).value;
    final notifications = authState?['settings']?['notifications'] ?? true;

    try {
      await ref.read(authNotifierProvider.notifier).updateSettings({
        'theme': theme,
        'notifications': notifications,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design geändert')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
