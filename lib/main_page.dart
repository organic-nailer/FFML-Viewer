import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:flutter_pcd/pcd_view.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Float32Array _vertices;
  late Float32Array _colors;

  @override
  void initState() {
    super.initState();
    final cube = genCube(21);
    _vertices = cube.$1;
    _colors = cube.$2;
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return PcdView(
              canvasSize: canvasSize, 
              vertices: _vertices, 
              colors: _colors,
            );
          }
        ),
      );
  }
}

(Float32Array, Float32Array) genCube(int sidePts) {
  // x y z
  final resultXYZ = Float32Array(sidePts * sidePts * sidePts * 3);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        resultXYZ[index * 3 + 0] = x / (sidePts - 1) - 0.5;
        resultXYZ[index * 3 + 1] = y / (sidePts - 1) - 0.5;
        resultXYZ[index * 3 + 2] = z / (sidePts - 1) - 0.5;
      }
    }
  }
  // r g b
  final resultRGB = Float32Array(sidePts * sidePts * sidePts * 3);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        resultRGB[index * 3 + 0] = x / (sidePts - 1);
        resultRGB[index * 3 + 1] = y / (sidePts - 1);
        resultRGB[index * 3 + 2] = z / (sidePts - 1);
      }
    }
  }
  print("done");
  return (resultXYZ, resultRGB);
}
