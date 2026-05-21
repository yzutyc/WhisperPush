import 'package:flutter/material.dart';

class AppTheme {
  // Dark theme colors
  static const Color darkSpaceBlue = Color(0xFF0F172A);
  static const Color darkSpaceIndigo = Color(0xFF1E293B);
  static const Color darkSpaceSlate = Color(0xFF334155);
  static const Color darkSpaceLight = Color(0xFF475569);
  static const Color darkTechPurple = Color(0xFF8B5CF6);
  static const Color darkTechPurpleLight = Color(0xFFA78BFA);
  static const Color darkNeonBlue = Color(0xFF06B6D4);
  static const Color darkNeonBlueLight = Color(0xFF22D3EE);
  static const Color darkPulseGreen = Color(0xFF10B981);
  static const Color darkPulseGreenLight = Color(0xFF34D399);
  static const Color darkWarningOrange = Color(0xFFF59E0B);
  static const Color darkDangerRed = Color(0xFFEF4444);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFE2E8F0);
  static const Color darkTextTertiary = Color(0xFFCBD5E1);
  static const Color darkTextDisabled = Color(0xFF94A3B8);
  static const Color darkBorderColor = Color(0xFF4B5563);
  static const Color darkBorderLight = Color(0xFF6B7280);

  // Light theme colors
  static const Color lightSpaceBlue = Color(0xFFF8FAFC);
  static const Color lightSpaceIndigo = Color(0xFFFFFFFF);
  static const Color lightSpaceSlate = Color(0xFFF1F5F9);
  static const Color lightSpaceLight = Color(0xFFE0E7FF);
  static const Color lightTechPurple = Color(0xFF7C3AED);
  static const Color lightTechPurpleLight = Color(0xFF8B5CF6);
  static const Color lightNeonBlue = Color(0xFF0891B2);
  static const Color lightNeonBlueLight = Color(0xFF06B6D4);
  static const Color lightPulseGreen = Color(0xFF059669);
  static const Color lightPulseGreenLight = Color(0xFF10B981);
  static const Color lightWarningOrange = Color(0xFFD97706);
  static const Color lightDangerRed = Color(0xFFDC2626);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextTertiary = Color(0xFF64748B);
  static const Color lightTextDisabled = Color(0xFF94A3B8);
  static const Color lightBorderColor = Color(0xFFE2E8F0);
  static const Color lightBorderLight = Color(0xFFCBD5E1);

  static bool _isDarkMode = true;

  static bool get isDarkMode => _isDarkMode;

  static void toggleTheme() {
    _isDarkMode = !_isDarkMode;
  }

  static void setThemeMode(bool dark) {
    _isDarkMode = dark;
  }

  static Color get spaceBlue => _isDarkMode ? darkSpaceBlue : lightSpaceBlue;
  static Color get spaceIndigo => _isDarkMode ? darkSpaceIndigo : lightSpaceIndigo;
  static Color get spaceSlate => _isDarkMode ? darkSpaceSlate : lightSpaceSlate;
  static Color get spaceLight => _isDarkMode ? darkSpaceLight : lightSpaceLight;
  static Color get techPurple => _isDarkMode ? darkTechPurple : lightTechPurple;
  static Color get techPurpleLight => _isDarkMode ? darkTechPurpleLight : lightTechPurpleLight;
  static Color get neonBlue => _isDarkMode ? darkNeonBlue : lightNeonBlue;
  static Color get neonBlueLight => _isDarkMode ? darkNeonBlueLight : lightNeonBlueLight;
  static Color get pulseGreen => _isDarkMode ? darkPulseGreen : lightPulseGreen;
  static Color get pulseGreenLight => _isDarkMode ? darkPulseGreenLight : lightPulseGreenLight;
  static Color get warningOrange => _isDarkMode ? darkWarningOrange : lightWarningOrange;
  static Color get dangerRed => _isDarkMode ? darkDangerRed : lightDangerRed;
  static Color get textPrimary => _isDarkMode ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => _isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get textTertiary => _isDarkMode ? darkTextTertiary : lightTextTertiary;
  static Color get textDisabled => _isDarkMode ? darkTextDisabled : lightTextDisabled;
  static Color get borderColor => _isDarkMode ? darkBorderColor : lightBorderColor;
  static Color get borderLight => _isDarkMode ? darkBorderLight : lightBorderLight;

  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(6));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(16));

  static ThemeData get currentTheme => _isDarkMode ? dark() : light();

  static ThemeData dark() {
    return ThemeData(
      primaryColor: darkTechPurple,
      colorScheme: const ColorScheme.dark(
        primary: darkTechPurple,
        secondary: darkNeonBlue,
        surface: darkSpaceIndigo,
        error: darkDangerRed,
      ),
      scaffoldBackgroundColor: darkSpaceBlue,
      cardColor: darkSpaceIndigo,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSpaceBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          backgroundColor: darkTechPurple,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: darkBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: darkTechPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: darkBorderColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: darkDangerRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: darkDangerRed, width: 2),
        ),
        filled: true,
        fillColor: darkSpaceIndigo,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: darkTextTertiary),
        prefixIconColor: darkTextTertiary,
        hintStyle: TextStyle(color: darkTextDisabled),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: darkTextPrimary),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: darkTextPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkTextPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: darkTextSecondary),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextTertiary),
        bodySmall: TextStyle(fontSize: 12, color: darkTextDisabled),
      ),
      iconTheme: const IconThemeData(color: darkTextSecondary),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        backgroundColor: darkSpaceSlate,
        labelStyle: TextStyle(fontSize: 12, color: darkTextSecondary),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        side: BorderSide(color: darkBorderColor),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: darkSpaceIndigo,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderColor,
        thickness: 0.5,
        space: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(darkTechPurple),
        trackColor: WidgetStateProperty.all(darkSpaceSlate),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(darkTechPurple),
        checkColor: WidgetStateProperty.all(darkTextPrimary),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      primaryColor: lightTechPurple,
      colorScheme: const ColorScheme.light(
        primary: lightTechPurple,
        secondary: lightNeonBlue,
        surface: lightSpaceIndigo,
        error: lightDangerRed,
      ),
      scaffoldBackgroundColor: lightSpaceBlue,
      cardColor: lightSpaceIndigo,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSpaceBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          backgroundColor: lightTechPurple,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: lightBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: lightTechPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: lightBorderColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: lightDangerRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: lightDangerRed, width: 2),
        ),
        filled: true,
        fillColor: lightSpaceSlate,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: lightTextTertiary),
        prefixIconColor: lightTextTertiary,
        hintStyle: TextStyle(color: lightTextDisabled),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: lightTextPrimary),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: lightTextPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: lightTextPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: lightTextSecondary),
        bodyMedium: TextStyle(fontSize: 14, color: lightTextTertiary),
        bodySmall: TextStyle(fontSize: 12, color: lightTextDisabled),
      ),
      iconTheme: const IconThemeData(color: lightTextSecondary),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadiusSmall),
        backgroundColor: lightSpaceSlate,
        labelStyle: TextStyle(fontSize: 12, color: lightTextSecondary),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        side: BorderSide(color: lightBorderColor),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: lightSpaceIndigo,
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorderColor,
        thickness: 0.5,
        space: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(lightTechPurple),
        trackColor: WidgetStateProperty.all(lightSpaceSlate),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(lightTechPurple),
        checkColor: WidgetStateProperty.all(lightTextPrimary),
      ),
    );
  }

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: _isDarkMode 
        ? const Color.fromARGB(180, 30, 41, 59)
        : Colors.white,
    borderRadius: borderRadius,
    border: Border.all(
        color: _isDarkMode
            ? const Color.fromARGB(80, 139, 92, 246)
            : lightBorderColor),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(60, 139, 92, 246),
              blurRadius: 25,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color.fromARGB(30, 6, 182, 212),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
  );

  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: _isDarkMode
        ? const Color.fromARGB(200, 30, 41, 59)
        : Colors.white,
    borderRadius: borderRadius,
    border: Border.all(
        color: _isDarkMode
            ? const Color.fromARGB(100, 139, 92, 246)
            : lightBorderColor),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(40, 0, 0, 0),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color.fromARGB(30, 139, 92, 246),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
  );

  static BoxDecoration get glassCardHoverDecoration => BoxDecoration(
    color: _isDarkMode
        ? const Color.fromARGB(220, 30, 41, 59)
        : Colors.white,
    borderRadius: borderRadius,
    border: Border.all(
        color: _isDarkMode
            ? const Color.fromARGB(150, 139, 92, 246)
            : lightTechPurple),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(80, 139, 92, 246),
              blurRadius: 30,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: const Color.fromARGB(40, 6, 182, 212),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ]
        : [
            BoxShadow(
              color: lightTechPurple.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
  );

  static BoxDecoration get glassLightDecoration => BoxDecoration(
    color: _isDarkMode
        ? const Color.fromARGB(240, 51, 65, 85)
        : lightSpaceSlate,
    borderRadius: borderRadiusSmall,
    border: Border.all(
        color: _isDarkMode
            ? const Color.fromARGB(60, 139, 92, 246)
            : lightBorderColor),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(30, 139, 92, 246),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ]
        : [],
  );

  static BoxDecoration get neonGlow => BoxDecoration(
    borderRadius: borderRadius,
    gradient: LinearGradient(
      colors: _isDarkMode
          ? [darkTechPurple, darkNeonBlue]
          : [lightTechPurple, lightNeonBlue],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(150, 139, 92, 246),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: const Color.fromARGB(100, 6, 182, 212),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ]
        : [
            BoxShadow(
              color: lightTechPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
  );

  static BoxDecoration get gradientBackground => BoxDecoration(
    color: _isDarkMode ? null : lightSpaceBlue,
    gradient: _isDarkMode
        ? LinearGradient(
            colors: [darkSpaceBlue, const Color(0xFF1E1B4B), darkSpaceBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : null,
  );

  static BoxDecoration get cardGradientBorder => BoxDecoration(
    color: spaceIndigo,
    borderRadius: borderRadius,
    border: Border.all(
      color: _isDarkMode
          ? const Color.fromARGB(120, 139, 92, 246)
          : lightBorderColor,
      width: 1,
    ),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(40, 139, 92, 246),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ]
        : [],
  );

  static BoxDecoration get neonButtonShadow => BoxDecoration(
    borderRadius: borderRadius,
    gradient: LinearGradient(
      colors: _isDarkMode
          ? [darkTechPurple, const Color(0xFF7C3AED)]
          : [lightTechPurple, const Color(0xFF6D28D9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(100, 139, 92, 246),
              blurRadius: 15,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: lightTechPurple.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
  );

  static BoxDecoration get neonButtonHoverShadow => BoxDecoration(
    borderRadius: borderRadius,
    gradient: LinearGradient(
      colors: _isDarkMode
          ? [darkTechPurpleLight, darkNeonBlueLight]
          : [lightTechPurpleLight, lightNeonBlueLight],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(150, 139, 92, 246),
              blurRadius: 25,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: const Color.fromARGB(100, 6, 182, 212),
              blurRadius: 15,
              spreadRadius: 4,
            ),
          ]
        : [
            BoxShadow(
              color: lightTechPurple.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
  );

  static BoxDecoration get searchInputDecoration => BoxDecoration(
    color: _isDarkMode
        ? const Color.fromARGB(200, 30, 41, 59)
        : Colors.white,
    borderRadius: borderRadius,
    border: Border.all(
        color: _isDarkMode
            ? const Color.fromARGB(60, 139, 92, 246)
            : lightBorderColor),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(20, 139, 92, 246),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
  );

  static BoxDecoration get searchInputFocusedDecoration => BoxDecoration(
    color: _isDarkMode
        ? const Color.fromARGB(220, 30, 41, 59)
        : Colors.white,
    borderRadius: borderRadius,
    border: Border.all(
        color: _isDarkMode
            ? const Color.fromARGB(150, 139, 92, 246)
            : lightTechPurple,
        width: 2),
    boxShadow: _isDarkMode
        ? [
            BoxShadow(
              color: const Color.fromARGB(60, 139, 92, 246),
              blurRadius: 20,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: const Color.fromARGB(30, 6, 182, 212),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ]
        : [
            BoxShadow(
              color: lightTechPurple.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
  );
}
