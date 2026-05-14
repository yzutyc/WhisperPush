import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.indigo;
  static const Color accentColor = Colors.teal;
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(8));

  static ThemeData light() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.indigo,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        backgroundColor: Colors.grey[100],
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 0.5,
        space: 8,
      ),
    );
  }

  static BoxDecoration cardShadow = BoxDecoration(
    color: cardColor,
    borderRadius: borderRadius,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 2,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration gradientButton = const BoxDecoration(
    borderRadius: borderRadius,
    gradient: LinearGradient(
      colors: [primaryColor, Color(0xFF5C6BC0)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  );
}