// lib/core/routes/global_navigation.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final Logger logger = Logger();

void redirectToLogin() {
  final context = navigatorKey.currentContext;
  if (context != null) {
    GoRouter.of(context).go('/login');
    logger.i("🚪 Redirected to login");
  } else {
    logger.w("⚠️ Could not redirect to login — context was null");
  }
}
