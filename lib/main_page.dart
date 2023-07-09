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
  final Float32Array _vertices = genCube(21);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void onTick(Duration duration) {
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

Float32Array genCube(int sidePts) {
  final result = Float32Array(sidePts * sidePts * sidePts * 3);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        result[index * 3 + 0] = x / (sidePts - 1) - 0.5;
        result[index * 3 + 1] = y / (sidePts - 1) - 0.5;
        result[index * 3 + 2] = z / (sidePts - 1) - 0.5;
      }
    }
  }
  print("done");
  return result;
}
