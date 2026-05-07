import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF16213E);

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9D5CF6);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonGreen = Color(0xFF00FF87);
  static const Color neonYellow = Color(0xFFFFE600);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonOrange = Color(0xFFFF6B00);

  static const Color xpColor = Color(0xFF00FF87);
  static const Color coinColor = Color(0xFFFFE600);
  static const Color streakColor = Color(0xFFFF6B00);

  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFF6D00);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textMuted = Color(0xFF6B6B8A);

  static const Color cardBorder = Color(0xFF2A2A4A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00FF87)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient levelGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFFF006E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
