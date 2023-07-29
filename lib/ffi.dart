import 'package:flutter_pcd/bridge_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

const base = "native";
late final dylib = loadLibForFlutter("$base.dll");
late final api = NativeImpl(dylib);
