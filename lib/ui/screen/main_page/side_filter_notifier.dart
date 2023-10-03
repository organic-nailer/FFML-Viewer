import 'package:flutter/material.dart';
import 'package:flutter_pcd/domain/pcd_filter.dart';

class SideFilterNotifier extends ChangeNotifier {
  final PcdFilter _filter = PcdFilter();

  PcdFilter get filter => _filter;

  void setDistance(RangeValues range) {
    _filter.distance = range;
    notifyListeners();
  }

  void setIntensity(RangeValues range) {
    _filter.intensity = range;
    notifyListeners();
  }

  void setAzimuth(RangeValues range) {
    _filter.azimuth = range;
    notifyListeners();
  }

  void setAltitude(RangeValues range) {
    _filter.altitude = range;
    notifyListeners();
  }
}

class SideFilterStateProvider extends InheritedNotifier<SideFilterNotifier> {
  static SideFilterNotifier of(BuildContext context, {bool listen = false}) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<SideFilterStateProvider>()!
          .notifier!;
    } else {
      return (context
              .getElementForInheritedWidgetOfExactType<
                  SideFilterStateProvider>()!
              .widget as SideFilterStateProvider)
          .notifier!;
    }
  }

  const SideFilterStateProvider(
      {super.key, required super.child, required super.notifier})
      : super();
}
