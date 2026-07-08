// Shared UI helpers for the Scene Party feature.
//
// Pack/character accent colors come from the server as hex strings
// (`primary_color_hex` etc.) — parsing them is the one sanctioned exception
// to the "no hardcoded color literals" rule.

import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// Parses a `RRGGBB` / `#RRGGBB` / `AARRGGBB` hex string into a [Color].
/// Falls back to [fallback] when the value is missing or malformed.
Color scenePackHexColor(String? hex, {Color fallback = AppTheme.primaryOrange}) {
  if (hex == null || hex.isEmpty) return fallback;
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  final value = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return value == null ? fallback : Color(value);
}
