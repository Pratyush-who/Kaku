import 'package:flutter/material.dart';

/// Centralized spacing, padding, radius, and duration tokens (Rule 12).
/// Enforces organic squircle and pill geometry ("dont use a square for details").
abstract final class AppSpacing {
  // --- Spacing / Insets ---
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // --- Symmetric Paddings ---
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 18.0,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 18.0,
  );

  // --- Organic Radii (Pills and Soft Squircles) ---
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radiusPill = 999.0;

  static final BorderRadius roundedSm = BorderRadius.circular(radiusSm);
  static final BorderRadius roundedMd = BorderRadius.circular(radiusMd);
  static final BorderRadius roundedLg = BorderRadius.circular(radiusLg);
  static final BorderRadius roundedXl = BorderRadius.circular(radiusXl);
  static final BorderRadius roundedPill = BorderRadius.circular(radiusPill);

  // Bottom Sheet / Top Curvature
  static const BorderRadius sheetTopCurvature = BorderRadius.vertical(
    top: Radius.circular(36.0),
  );

  // --- Animation Durations ---
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 600);
  static const Duration durationSplash = Duration(milliseconds: 2200);

  // --- Curves ---
  static const Curve curveSpring = Curves.easeOutCubic;
  static const Curve curveSmooth = Curves.easeInOutCubic;
}
