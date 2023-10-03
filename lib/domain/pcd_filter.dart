import 'package:flutter/material.dart';

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
