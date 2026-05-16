import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Surfaces ─────────────────────────────────────────────────────────
  static const Color background   = Color(0xFF08090C);
  static const Color surface1     = Color(0xFF0F1014);
  static const Color surface2     = Color(0xFF161820);
  static const Color border       = Color(0xFF1E2128);
  static const Color borderSubtle = Color(0xFF13141A);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color textMuted     = Color(0xFF4A4A5A);

  // ── Role accents ─────────────────────────────────────────────────────
  static const Color resident = Color(0xFF10B981); // emerald
  static const Color worker   = Color(0xFFF59E0B); // amber
  static const Color manager  = Color(0xFF6366F1); // indigo
  static const Color owner    = Color(0xFFA855F7); // purple

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success  = Color(0xFF10B981);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = Color(0xFFEF4444);
  static const Color info     = Color(0xFF38BDF8);
}
