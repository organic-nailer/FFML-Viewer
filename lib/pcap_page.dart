import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:flutter_pcd/ffi.dart';
import 'package:flutter_pcd/hesai_pcap_parser.dart';
import 'package:flutter_pcd/pcd_view.dart';
import 'package:color_map/color_map.dart';
import 'dart:math' as math;

class PcapPage extends StatefulWidget {
  const PcapPage({Key? key}) : super(key: key);

  @override
  State<PcapPage> createState() => _PcapPageState();
}

class _PcapPageState extends State<PcapPage> {
  int selectedFrame = 1;
  int maxFrameNum = 0;
  late int maxPointNum;
  // List<List<VeloPoint>> frames = [];
  List<(Float32List, Float32List)> _vertices = [];

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                _vertices.isNotEmpty ? Positioned.fill(
                  child: PcdView(
                    canvasSize: canvasSize, 
                    vertices: _vertices[selectedFrame].$1,
                    colors: _vertices[selectedFrame].$2,
                    backgroundColor: Colors.grey.shade600,
                    maxPointNum: maxPointNum,
                  ),
                ) : const Center(child: Text("no data")),
                if (maxFrameNum > 0) Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("frame: $selectedFrame/$maxFrameNum", style: const TextStyle(color: Colors.amber),),
                      Container(
                        width: 500,
                        height: 50,
                        child: Slider(
                          value: selectedFrame.toDouble(),
                          min: 0,
                          max: maxFrameNum.toDouble(),
                          divisions: maxFrameNum,
                          onChanged: (value) {
                            setState(() {
                              selectedFrame = value.toInt();
                            });
                          },
                        ),
                      ),
                    ],
                  )
                )
              ],
            );
          }
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.file_upload),
          onPressed: () async {
            // final pointCloud = genCube(21);
            // setState(() {
            //   _vertices = pointCloud.$1;
            //   _colors = pointCloud.$2;
            // });
            const typeGroup = XTypeGroup(
              label: "point cloud(xt32)",
              extensions: ["pcap"],
            );
            final file = await openFile(acceptedTypeGroups: [typeGroup]);
            if (file == null) {
              print("no file selected");
              return;
            }
            final path = file.path;
            final stopwatch = Stopwatch()..start();
            final videoData = await api.readPcap(path: path);
            stopwatch.stop();
            print("read pcap took ${stopwatch.elapsedMilliseconds}ms");
            print("loaded ${videoData.vertices.length} frames");
            print("max point num: ${videoData.maxPointNum}");
            setState(() {
              _vertices = videoData.vertices;
              maxFrameNum = videoData.vertices.length - 1;
              maxPointNum = videoData.maxPointNum;
            });
            // final parser = HesaiPcapParser(file);
            // await parser.readPcap();

            // final pointClouds = parser.frames.map((frame) => readVeloPoints(frame)).toList();
            // setState(() {
            //   frames = parser.frames;
            //   _vertices = pointClouds;
            //   maxFrameNum = parser.frames.length - 1;
            //   maxPointNum = pointClouds.map((f) => f.$1.length).reduce(math.max);
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

(Float32Array, Float32Array) readVeloPoints(List<VeloPoint> points) {
  final pointLen = points.length;
  final resultXYZ = Float32Array(pointLen * 3);
  final resultRGB = Float32Array(pointLen * 3);
  final cmap = Colormaps.turbo;
  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    resultXYZ[i * 3 + 0] = point.x;
    resultXYZ[i * 3 + 1] = point.y;
    resultXYZ[i * 3 + 2] = point.z;
    final color = cmap(point.reflectivity / 255);
    resultRGB[i * 3 + 0] = color.r;
    resultRGB[i * 3 + 1] = color.g;
    resultRGB[i * 3 + 2] = color.b;
  }
  return (resultXYZ, resultRGB);
}
