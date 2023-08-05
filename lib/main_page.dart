import 'dart:math';
import 'dart:typed_data';

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
  late Float32List _vertices;
  int counter = 0;

  @override
  void initState() {
    super.initState();
    _vertices = genCube(10);
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
              // colors: _colors.toDartList(),
              maxPointNum: 29*29*29,
              backgroundColor: Colors.grey,
            );
          }
        ),
        floatingActionButton: FloatingActionButton(
          child: Text("$counter"),
          onPressed: () async {
            final pointCloud = genCube(Random().nextInt(20) + 10);
            setState(() {
              _vertices = pointCloud;
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

Float32List genCube(int sidePts) {
  // x y z
  final result = Float32List(sidePts * sidePts * sidePts * 6);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        result[index * 6 + 0] = x / (sidePts - 1) - 0.5;
        result[index * 6 + 1] = y / (sidePts - 1) - 0.5;
        result[index * 6 + 2] = z / (sidePts - 1) - 0.5;
        result[index * 6 + 3] = x / (sidePts - 1);
        result[index * 6 + 4] = y / (sidePts - 1);
        result[index * 6 + 5] = z / (sidePts - 1);
      }
    }
  }
  return result;
}
