import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:flutter_pcd/pcd_view.dart';
import 'package:color_map/color_map.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Float32Array _vertices;
  late Float32Array _colors;
  int counter = 0;

  @override
  void initState() {
    super.initState();
    final cube = genCube(5);
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
              maxPointNum: 29*29*29,
              backgroundColor: Colors.grey.shade900,
            );
          }
        ),
        floatingActionButton: FloatingActionButton(
          child: Text("$counter"),
          onPressed: () async {
            final pointCloud = genCube(Random().nextInt(20) + 10);
            setState(() {
              _vertices = pointCloud.$1;
              _colors = pointCloud.$2;
              counter++;
            });
            // const typeGroup = XTypeGroup(
            //   label: "point cloud",
            //   extensions: ["csv"],
            // );
            // final file = await openFile(acceptedTypeGroups: [typeGroup]);
            // if (file == null) {
            //   print("no file selected");
            //   return;
            // }
            // final content = await file.readAsString();
            // final pointCloud = readVeloCsv(content);
            // setState(() {
            //   _vertices = pointCloud.$1;
            //   _colors = pointCloud.$2;
            // });
          },
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

(Float32Array, Float32Array) readVeloCsv(String content) {
  final table = const CsvToListConverter().convert(content);
  final pointLen = table.length - 1;
  final resultXYZ = Float32Array(pointLen * 3);
  final resultRGB = Float32Array(pointLen * 3);
  final cmap = Colormaps.turbo;
  for (var i = 1; i < table.length; i++) {
    final row = table[i];
    resultXYZ[(i - 1) * 3 + 0] = row[7];
    resultXYZ[(i - 1) * 3 + 1] = row[8];
    resultXYZ[(i - 1) * 3 + 2] = row[9];
    final color = cmap(row[0] / 255);
    resultRGB[(i - 1) * 3 + 0] = color.r;
    resultRGB[(i - 1) * 3 + 1] = color.g;
    resultRGB[(i - 1) * 3 + 2] = color.b;
  }
  return (resultXYZ, resultRGB);
}
