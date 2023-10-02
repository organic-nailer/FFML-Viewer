import 'package:flutter/material.dart';

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
      return context.dependOnInheritedWidgetOfExactType<SideFilterStateProvider>()!.notifier!;
    } else {
      return (context.getElementForInheritedWidgetOfExactType<SideFilterStateProvider>()!.widget as SideFilterStateProvider).notifier!;
    }
  }

  SideFilterStateProvider({super.key, required super.child})
      : super(notifier: SideFilterNotifier());
}

class PcdFilter {
  static const RangeValues distanceMinMax = RangeValues(0, 300);
  static const RangeValues intensityMinMax = RangeValues(0, 255);
  static const RangeValues azimuthMinMax = RangeValues(0, 36000);
  static const RangeValues altitudeMinMax = RangeValues(-9000, 9000);

  RangeValues distance;
  RangeValues intensity;
  RangeValues azimuth;
  RangeValues altitude;

  PcdFilter()
  : distance = distanceMinMax,
    intensity = intensityMinMax,
    azimuth = azimuthMinMax,
    altitude = altitudeMinMax;
}
