import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Orange (signature de la marque) ──────────────────────────────
  static const Color primary = Color(0xFFF07C00);
  static const Color primaryLight = Color(0xFFFF9A2E);
  static const Color primaryDark = Color(0xFFD46A00);

  // ── Accent (deep navy) ────────────────────────────────────────────────────
  static const Color accent = Color(0xFF1A1A2E);
  static const Color accentLight = Color(0xFF2D2D44);

  // ── Background crème/beige ────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF7F4EF);
  static const Color surfaceLight = Color(0xFFFFFBF7);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F18);
  static const Color surfaceDark = Color(0xFF16161F);
  static const Color cardDark = Color(0xFF1E1E2C);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0A0A);
  static const Color grey50 = Color(0xFFF9F9F9);
  static const Color grey100 = Color(0xFFF2F2F2);
  static const Color grey200 = Color(0xFFE8E8E8);
  static const Color grey300 = Color(0xFFD0D0D0);
  static const Color grey400 = Color(0xFFAAAAAA);
  static const Color grey500 = Color(0xFF777777);
  static const Color grey600 = Color(0xFF555555);
  static const Color grey700 = Color(0xFF333333);
  static const Color grey800 = Color(0xFF222222);
  static const Color grey900 = Color(0xFF111111);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textTertiary = Color(0xFFAAAAAA);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFBBBBCC);

  // ── Card gradients ────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8C00), Color(0xFFF07C00)],
  );

  static const LinearGradient cardSignatureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44), Color(0xFF3A3A55)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardPlatinumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B7355), Color(0xFFA08060), Color(0xFFBD9A75)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardDebitGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B00), Color(0xFFF07C00), Color(0xFFE08500)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardNavyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF4F46E5)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
  );

  static const LinearGradient balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D50)],
  );

  // ── Action colors ─────────────────────────────────────────────────────────
  static const Color depositColor = Color(0xFF22C55E);
  static const Color withdrawColor = Color(0xFFEF4444);
  static const Color transferColor = Color(0xFF3B82F6);
  static const Color paymentColor = Color(0xFFF07C00);
  static const Color rechargeColor = Color(0xFF8B5CF6);
  static const Color airtimeColor = Color(0xFF06B6D4);
  static const Color servicesColor = Color(0xFFEC4899);

  // ── Border ────────────────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFF2A2A3A);
  static const Color borderFocus = Color(0xFFF07C00);
}
