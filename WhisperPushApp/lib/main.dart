import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'components/web_container.dart';
import 'pages/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

const double kMinWindowWidth = 390.0;
const double kMinWindowHeight = 844.0;
const double kMaxWindowWidth = 430.0;
const double kMaxWindowHeight = 932.0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(kMinWindowWidth, kMinWindowHeight),
      minimumSize: Size(kMinWindowWidth, kMinWindowHeight),
      maximumSize: Size(kMaxWindowWidth, kMaxWindowHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'WhisperPush',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // 确保 AppTheme 与 ThemeProvider 同步
          AppTheme.setThemeMode(themeProvider.isDarkMode);
          
          Widget materialApp = MaterialApp(
            key: ValueKey(themeProvider.isDarkMode), // 强制重建
            title: 'WhisperPush',
            theme: AppTheme.currentTheme,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );

          if (kIsWeb) {
            return WebContainer(child: materialApp);
          }

          return materialApp;
        },
      ),
    );
  }
}
