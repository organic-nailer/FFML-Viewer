import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

Color getSurfaceContainer(BuildContext context) {
  final seedColor = Theme.of(context).colorScheme.primary;
  final darkMode = Theme.of(context).colorScheme.brightness == Brightness.dark;
  CorePalette p = CorePalette.of(seedColor.value);
  return Color(p.neutral.get(darkMode ? 12 : 94));
}

Color getSurfaceContainerLowest(BuildContext context) {
  final seedColor = Theme.of(context).colorScheme.primary;
  final darkMode = Theme.of(context).colorScheme.brightness == Brightness.dark;
  CorePalette p = CorePalette.of(seedColor.value);
  return Color(p.neutral.get(darkMode ? 4 : 100));
}