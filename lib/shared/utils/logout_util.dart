import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:domyturn/core/storage/secure_storage_service.dart';
import 'package:domyturn/core/session/app_session.dart'; // Required if you store session data in memory

class LogoutUtil {
  static Future<void> confirmAndLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureStorageService().deleteAll(); // ✅ Remove tokens and sensitive data
      AppSession.instance.clear(); // ✅ Clear any in-memory session cache
      if (context.mounted) context.go('/login'); // ✅ Navigate to login screen
    }
  }

  static Future<void> forceLogout(BuildContext context) async {
    await _doLogout(context);
  }

  static Future<void> _doLogout(BuildContext context) async {
    await SecureStorageService().deleteAll();
    AppSession.instance.clear();
    if (context.mounted) context.go('/login');
  }
}
