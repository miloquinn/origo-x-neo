import 'package:flutter/material.dart';

/// Display data for an item in a floating pill navigation bar.
class FloatingPillNavigationItem {
  const FloatingPillNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
