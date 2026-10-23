import 'package:flutter/material.dart';

const Color upGold = Color(0xFFD6A16C);
const Color upRose = Color(0xFFE6A681);
const Color upDark = Color(0xFF090604);
const Color upPanel = Color(0xFF17120F);
const Color upCream = Color(0xFFFFF5EB);

ThemeData buildUpTheme({required bool dark}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: upGold,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? upGold : const Color(0xFF8D633B),
    secondary: upRose,
    surface: dark ? const Color(0xFF17120F) : const Color(0xFFFFFCF7),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? upDark : const Color(0xFFF5F0E8),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? upDark : const Color(0xFFF5F0E8),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF17120F) : const Color(0xFFFFFCF7),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: dark ? const Color(0xFF443426) : const Color(0xFFE0D3C3))),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF211A15) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: dark ? upDark : Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: dark ? const Color(0xFF15110D) : Colors.white, indicatorColor: scheme.primary.withValues(alpha: .18), labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
    dividerColor: scheme.outlineVariant,
    textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light).textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
  );
}
