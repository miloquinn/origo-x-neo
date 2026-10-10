import 'package:flutter/material.dart';
import '../models/app_skin.dart';

/// Display data for an item in a floating pill navigation bar.
class FloatingPillNavigationItem {
  const FloatingPillNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.skinSlot,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final AppSkinIconSlot? skinSlot;
}
