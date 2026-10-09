import 'package:flutter/material.dart';

/// Hệ thống màu sắc chuẩn 100% theo thiết kế DaLatTrip
class AppColors {
  AppColors._();

  // Primary Colors (Xanh rừng thông Đà Lạt đặc trưng)
  static const Color primary = Color(0xFF1E3A2F);
  static const Color primaryDark = Color(0xFF142720);
  static const Color primaryLight = Color(0xFF2E5343);
  static const Color primaryAccent = Color(0xFF3E6F5B);

  // Mint / Badge Colors (Huy hiệu tròn & icon nền xanh bạc hà)
  static const Color mintBadge = Color(0xFFDCEEE5);
  static const Color mintBadgeLight = Color(0xFFEAF5EE);
  static const Color mintIcon = Color(0xFF2B5844);

  // Background & Surface
  static const Color background = Color(0xFFF7FAF8);
  static const Color scaffoldBackground = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color sheetBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF16241E);
  static const Color textSecondary = Color(0xFF6B7E76);
  static const Color textMuted = Color(0xFF96A59E);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF1E3A2F);

  // Form & Inputs
  static const Color inputBackground = Color(0xFFF5F8F6);
  static const Color inputBorder = Color(0xFFE4EDE7);
  static const Color inputBorderFocused = Color(0xFF1E3A2F);
  static const Color inputIcon = Color(0xFF7D9088);
  static const Color inputHint = Color(0xFFA4B3AC);

  // Social Buttons
  static const Color socialButtonBg = Color(0xFFFFFFFF);
  static const Color socialButtonBorder = Color(0xFFE4EDE7);
  static const Color border = Color(0xFFE4EDE7);
  static const Color divider = Color(0xFFE5ECE8);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);

  // Gradients
  static LinearGradient get forestGradient => const LinearGradient(
    colors: [Color(0xFF1E3A2F), Color(0xFF142720)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get mistyHeaderGradient => LinearGradient(
    colors: [
      const Color(0xFF9DBEAD).withValues(alpha: 0.35),
      const Color(0xFFDDECE3).withValues(alpha: 0.2),
      Colors.white,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
