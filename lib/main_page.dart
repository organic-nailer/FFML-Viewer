import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:flutter_pcd/pcd_view.dart';
// import 'package:vector_math/vector_math.dart' hide Colors;

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  Size _canvasSize = const Size(500, 500);
  late Ticker _ticker;
  final ColorTween _colorTween = ColorTween(begin: Colors.red, end: Colors.blue);
  Color _color = Colors.red;
  Matrix4 _transform = Matrix4.identity();
  late Float32Array _vertices;
  late Float32Array _colors;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(onTick)..start();
    final cube = genCube(21);
    _vertices = cube.$1;
    _colors = cube.$2;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Duration past = Duration.zero;
  void onTick(Duration duration) {
    if ((duration - past).inSeconds >= 5) {
      past = duration;
    }
    else {
      return;
    }
    const phaseLengthMs = 10000;
    final phase = (duration.inMilliseconds % phaseLengthMs) / phaseLengthMs;
    final phaseRad = phase * 2 * math.pi;
    setState(() {
      _color = _colorTween.transform(phase)!;
      _transform = Matrix4.identity()
        ..rotateX(10 * math.pi / 180)
        ..rotateY(phaseRad);
    });
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: Center(
          child: PcdView(
            canvasSize: _canvasSize, 
            vertices: _vertices, 
            colors: _colors,
            transform: _transform,
          )
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     final randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
        //     render(_flutterGlPlugin.gl, _canvasSize, _glProgram, randomColor, 0);
        //   },
        //   tooltip: 'Increment',
        //   child: const Icon(Icons.add),
        // ),
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
