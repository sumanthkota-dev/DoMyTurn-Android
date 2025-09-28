import 'package:flutter/material.dart';

/// Snackbar types for styling and semantics
enum SnackbarType { error, success, info }

class GlobalScaffold {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSnackbar(
      String message, {
        SnackbarType type = SnackbarType.info,
        String? actionLabel,
        VoidCallback? onAction,
        Duration duration = const Duration(seconds: 4),
      }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    // 🎨 Material 3 expressive color & icon mapping
    final ColorScheme colorScheme = ThemeData().colorScheme;
    late Color backgroundColor;
    late IconData icon;

    switch (type) {
      case SnackbarType.error:
        backgroundColor = Colors.red.shade700;
        icon = Icons.error_outline;
        break;
      case SnackbarType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        break;
      case SnackbarType.info:
      default:
        backgroundColor = Colors.blueGrey.shade700;
        icon = Icons.info_outline;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.25,
                ),
              ),
            ),
          ],
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
          textColor: Colors.white,
        )
            : null,
      ),
    );
  }
}
