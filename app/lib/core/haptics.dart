// The seven-word haptic language (NATIVE.md section 5).
// Never on scroll. Never on errors. Bloom is sacred.

import 'package:flutter/services.dart';

class Haptics {
  static bool enabled = true;

  /// Selection whisper: the 25/50/75 marks of a hold.
  static void tick() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// A card or state settling into place.
  static void settle() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// A promise completed (the Thumb Promise lands).
  static void commit() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Sacred moments only: planting, pledge, growth.
  static void bloom() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Your drop joining the rain: a warm double tap.
  static Future<void> yourDrop() async {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.lightImpact();
  }
}
