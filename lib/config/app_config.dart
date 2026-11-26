import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminColors {
  static const Color primary = Color(0xFF00E07E);
  static const Color primaryDark = Color(0xFF064E3B);
  static const Color primaryAccent = Color(0xFF047857);
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color background = Color(0xFFF3F6F9);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF8FAFC);
  static const Color textHeadline = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF6366F1);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}

class AdminTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AdminColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdminColors.primaryAccent,
        primary: AdminColors.primaryAccent,
        secondary: AdminColors.secondary,
        surface: AdminColors.surface,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AdminColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AdminColors.primaryAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class AdminConfig {
  static String baseUrl = 'https://ryzprjkt.cloud';
  static const String apiPrefix = '/api';
  static const Duration timeoutDuration = Duration(seconds: 20);

  static String get apiBaseUrl => '$baseUrl$apiPrefix';
  static String get adminBaseUrl => '$apiBaseUrl/admin';
  static String get loginUrl => '$apiBaseUrl/auth/login';
  static String get logoutUrl => '$apiBaseUrl/auth/logout';

  static String endpoint(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    return '$adminBaseUrl$clean';
  }

  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String rupiah(dynamic amount) {
    final val = num.tryParse(amount?.toString() ?? '0') ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }
}

