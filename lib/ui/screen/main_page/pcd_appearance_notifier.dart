import 'package:flutter/material.dart';

class PcdAppearanceNotifier extends ChangeNotifier {
  double _pointSize = 1.0;
  double get pointSize => _pointSize;
  Color _backgroundColor = Colors.black;
  Color get backgroundColor => _backgroundColor;

  void setPointSize(double size) {
    _pointSize = size;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }
}

class PcdAppearanceStateProvider extends InheritedNotifier<PcdAppearanceNotifier> {
  static PcdAppearanceNotifier of(BuildContext context, {bool listen = false}) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<PcdAppearanceStateProvider>()!
          .notifier!;
    } else {
      return (context
              .getElementForInheritedWidgetOfExactType<PcdAppearanceStateProvider>()!
              .widget as PcdAppearanceStateProvider)
          .notifier!;
    }
  }

  const PcdAppearanceStateProvider(
      {super.key, required super.child, required super.notifier})
      : super();
}
