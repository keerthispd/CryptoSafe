import 'package:flutter/material.dart';

import 'screens/bootstrap_screen.dart';
import 'screens/biometric_bridge_screen.dart';
import 'screens/biometric_native_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/file_detail_screen.dart';
import 'screens/file_editor_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/password_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';

class CryptoSafeApp extends StatelessWidget {
  const CryptoSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CryptoSafe Mobile',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Trebuchet MS',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6EE7B7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF06101B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF081627),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B1320),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x3F9FB0C2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6EE7B7), width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0B1320).withOpacity(0.86),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          margin: const EdgeInsets.all(0),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF0B1320),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0x14000000),
          side: const BorderSide(color: Color(0x339FB0C2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          labelStyle: const TextStyle(color: Colors.white),
          selectedColor: const Color(0xFF6EE7B7),
          secondarySelectedColor: const Color(0xFF6EE7B7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6EE7B7),
            foregroundColor: const Color(0xFF02131F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0x4D9FB0C2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      routes: {
        '/': (_) => const BootstrapScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/password': (_) => const PasswordScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/file-editor': (_) => const FileEditorScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/file-detail') {
          final fileId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => FileDetailScreen(fileId: fileId),
          );
        }
        if (settings.name == '/biometric-bridge') {
          final args = settings.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
          return MaterialPageRoute(
            builder: (_) => BiometricNativeScreen(arguments: args),
          );
        }
        if (settings.name == '/biometric-webview') {
          final args = settings.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
          return MaterialPageRoute(
            builder: (_) => BiometricBridgeScreen(arguments: args),
          );
        }
        return null;
      },
      initialRoute: '/',
    );
  }
}

