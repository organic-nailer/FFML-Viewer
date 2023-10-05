import 'dart:typed_data';

import 'package:flutter_pcd/bridge_definitions.dart';
import 'package:flutter_pcd/ffi.dart';

class SolidAngleImageBuilder {
  Future<Uint8List> build(Float32List otherData, Float32List mask, SolidAngleImageConfig config) async {
    return api.generateSolidAngleImage(otherData: otherData, mask: mask, config: config);
  }
}