import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F0FF),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: Colors.black.withAlpha(26),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryContainer,
      selectedColor: AppColors.primary,
      disabledColor: Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: const TextStyle(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(color: AppColors.onPrimary),
      brightness: Brightness.light,
    ),
    iconTheme: const IconThemeData(color: AppColors.primary),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected) ? AppColors.primary : Colors.grey,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : Colors.grey,
        );
      }),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1B2E),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF2D2A3E),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: Colors.black.withAlpha(26),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2D2A3E),
      selectedColor: AppColors.primary,
      disabledColor: Colors.grey.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: const TextStyle(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(color: AppColors.onPrimary),
      brightness: Brightness.dark,
    ),
    iconTheme: const IconThemeData(color: AppColors.primary),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected) ? AppColors.primary : Colors.grey,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : Colors.grey,
        );
      }),
    ),
  );
}
