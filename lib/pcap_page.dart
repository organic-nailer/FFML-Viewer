import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcd/ffi.dart';
import 'package:flutter_pcd/pcap_manager.dart';
import 'package:flutter_pcd/pcd_view.dart';

class PcapPage extends StatefulWidget {
  const PcapPage({Key? key}) : super(key: key);

  @override
  State<PcapPage> createState() => _PcapPageState();
}

class _PcapPageState extends State<PcapPage> {
  int selectedFrame = 1;
  // int maxFrameNum = 0;
  int maxPointNum = 128000;
  // List<List<VeloPoint>> frames = [];
  // List<Float32List> _vertices = [];
  PcapManager? _pcapManager;

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                (_pcapManager?.length ?? 0) > 0 ? Positioned.fill(
                  child: PcdView(
                    canvasSize: canvasSize, 
                    vertices: _pcapManager![selectedFrame],
                    backgroundColor: Colors.grey.shade600,
                    maxPointNum: maxPointNum,
                  ),
                ) : const Center(child: Text("no data")),
                if ((_pcapManager?.length ?? 0) > 0) Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("frame: $selectedFrame/${_pcapManager!.length}", style: const TextStyle(color: Colors.amber),),
                      Container(
                        width: 500,
                        height: 50,
                        child: Slider(
                          value: selectedFrame.toDouble(),
                          min: 0,
                          max: _pcapManager!.length.toDouble(),
                          divisions: _pcapManager!.length,
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
          child: const Icon(Icons.file_upload),
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
            _pcapManager = PcapManager("", path);
            _pcapManager!.addListener(() {
              print("pcapManager changed ${_pcapManager!.length}");
              setState(() { });
            });
            // final stopwatch = Stopwatch()..start();
            // final videoData = await api.readPcap(path: path);
            // stopwatch.stop();
            // print("read pcap took ${stopwatch.elapsedMilliseconds}ms");
            // print("loaded ${videoData.frameStartIndices.length} frames");
            // print("max point num: ${videoData.maxPointNum}");
            // final newVertices = <Float32List>[];
            // for (var i = 0; i < videoData.frameStartIndices.length; i++) {
            //   final start = videoData.frameStartIndices[i];
            //   final end = i == videoData.frameStartIndices.length - 1 ? videoData.vertices.length : videoData.frameStartIndices[i + 1];
            //   newVertices.add(videoData.vertices.sublist(start, end));
            // }
            // setState(() {
            //   _vertices = newVertices;
            //   maxFrameNum = videoData.frameStartIndices.length - 1;
            //   maxPointNum = videoData.maxPointNum;
            // });
            // print(_vertices[1].length);
            // print(_vertices[1].sublist(0, 10));
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
