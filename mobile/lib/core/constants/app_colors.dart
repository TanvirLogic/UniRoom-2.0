import 'package:flutter/material.dart';

/// Modern, Minimalistic Sky Blue, Blue & White Palette for UniRoom-Live 2.0
class AppColors {
  // Brand Blues
  static const Color primarySky = Color(0xFF0284C7); // Vibrant Sky Blue
  static const Color primaryDark = Color(0xFF0369A1); // Deep Ocean Blue
  static const Color primaryLight = Color(0xFFE0F2FE); // Soft Sky Tint (Cards/Pills)
  static const Color iceBlue = Color(0xFFF0F9FF); // Softest Ice Blue Fill
  static const Color accentBlue = Color(0xFF1D4ED8); // Royal High-Contrast Blue
  static const Color skyHighlight = Color(0xFF38BDF8); // Bright Sky Pulse

  // Whites & Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White Cards
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Subtle Input Fill

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF0F172A); // Deep Slate
  static const Color textSecondary = Color(0xFF475569); // Clear Slate Grey
  static const Color textMuted = Color(0xFF94A3B8); // Placeholder Muted Grey

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Subtle 1px Border
  static const Color borderSky = Color(0xFFBAE6FD); // Sky Tint Border
  static const Color borderFocused = Color(0xFF0284C7); // Focused Input Sky Blue

  // Functional Status
  static const Color success = Color(0xFF10B981); // Running Class / Available Green
  static const Color error = Color(0xFFEF4444); // Cancelled / Occupied Red
  static const Color warning = Color(0xFFF59E0B); // Upcoming Class Amber

  // Pre-configured Gradients
  static const LinearGradient skyHeroGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient iceCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Soft Sky Drop Shadow
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primarySky.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: primarySky.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
