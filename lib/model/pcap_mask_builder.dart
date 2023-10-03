import 'dart:typed_data';

import 'package:flutter_pcd/domain/pcd_filter.dart';
import 'package:flutter_pcd/model/pcap_manager.dart';

class PcapMaskBuilder {
  Float32List buildMask(DisplayPcdFrame frame, PcdFilter filter) {
    var mask = Float32List(frame.pointNum);
    for (var i = 0; i < frame.pointNum; i++) {
      // intensity
      if (frame.otherData[i * 6] < filter.intensity.start ||
          frame.otherData[i * 6] > filter.intensity.end) {
        mask[i] = 0.0;
        continue;
      }
      // distance
      if (frame.otherData[i * 6 + 3] < filter.distance.start ||
          frame.otherData[i * 6 + 3] > filter.distance.end) {
        mask[i] = 0.0;
        continue;
      }
      // azimuth
      if (frame.otherData[i * 6 + 2] < filter.azimuth.start ||
          frame.otherData[i * 6 + 2] > filter.azimuth.end) {
        mask[i] = 0.0;
        continue;
      }
      // altitude
      if (frame.otherData[i * 6 + 1] < filter.altitude.start ||
          frame.otherData[i * 6 + 1] > filter.altitude.end) {
        mask[i] = 0.0;
        continue;
      }
      mask[i] = 1.0;
    }
    return mask;
  }
}
