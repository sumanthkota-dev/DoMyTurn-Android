import 'package:domyturn/shared/utils/global_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bootstrap/app_initializer.dart';
import 'core/routes/app_router.dart';
import 'core/routes/global_navigation.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();

  final initialRoute = await AppInitializer.determineInitialRoute();

  runApp(
    ProviderScope(
      child: DoMyTurnApp(initialRoute: initialRoute),
    ),
  );
}


class DoMyTurnApp extends StatelessWidget {
  final String initialRoute;
  const DoMyTurnApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: GlobalScaffold.messengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router(initialRoute,navigatorKey),

    );
  }
}
