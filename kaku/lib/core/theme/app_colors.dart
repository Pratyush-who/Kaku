import 'package:flutter/material.dart';

/// Centralized color palette for Kaku (Japanese: 描く - "to sketch/draw").
/// Built with an Obsidian Studio aesthetic: deep midnight canvas,
/// luminous aurora emerald/teal accents, electric indigo highlights,
/// and frosted glass surfaces.
abstract final class AppColors {
  // --- Dark Palette (Default Obsidian Studio) ---
  static const Color darkCanvas = Color(0xFF090B10);
  static const Color darkBackground = Color(0xFF0D111A);
  static const Color darkSurface = Color(0xFF131824);
  static const Color darkSurfaceElevated = Color(0xFF1A2232);
  static const Color darkSurfaceCard = Color(0xFF161D2B);
  static const Color darkBorder = Color(0x1AFFFFFF);
  static const Color darkBorderHighlight = Color(0x3300F2A9);

  // --- Luminous Accents ---
  static const Color accentPrimary = Color(0xFF00F2A9); // Aurora Emerald / Neon Mint
  static const Color accentPrimaryGlow = Color(0x4D00F2A9);
  static const Color accentSecondary = Color(0xFF6366F1); // Electric Indigo
  static const Color accentCyan = Color(0xFF00D2FF); // Cyan Flare
  static const Color accentPurple = Color(0xFFA855F7); // Violet Sketch

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F2A9), Color(0xFF00C9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGlowGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF00F2A9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    colors: [
      Color(0x2B24334C),
      Color(0x14121927),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF151C2A), Color(0xFF0D121B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Text Colors (Dark Mode) ---
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color textDisabledDark = Color(0xFF475569);

  // --- Status & Feedback ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // --- Light Palette (for clean Dark/Light theming per Rule 12) ---
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
}
