import 'package:flutter/material.dart';
import 'package:flutter_pcd/bridge_definitions.dart';

class SolidAngleImageConfigNotifier extends ChangeNotifier {
  final SolidAngleImageConfig config = const SolidAngleImageConfig(
    aziStart: 0,
    aziEnd: 36000,
    aziStep: 100,
    altStart: 16,
    altEnd: -15,
    altStep: -1,
  );
}

class SolidAngleImageConfigStateProvider extends InheritedNotifier<SolidAngleImageConfigNotifier> {
  static SolidAngleImageConfigNotifier of(BuildContext context, {bool listen = false}) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<SolidAngleImageConfigStateProvider>()!
          .notifier!;
    } else {
      return (context
              .getElementForInheritedWidgetOfExactType<
                  SolidAngleImageConfigStateProvider>()!
              .widget as SolidAngleImageConfigStateProvider)
          .notifier!;
    }
  }

  const SolidAngleImageConfigStateProvider(
      {Key? key, required Widget child, required SolidAngleImageConfigNotifier notifier})
      : super(key: key, child: child, notifier: notifier);
}