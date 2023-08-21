import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/bridge_definitions.dart';
import 'package:flutter_pcd/ffi.dart';
import 'package:flutter_pcd/pcd_view.dart';

class StreamPage extends StatefulWidget {
  const StreamPage({Key? key}) : super(key: key);
  @override
  StreamPageState createState() => StreamPageState();
}

class StreamPageState extends State<StreamPage> {
  Stream<PcdFragment>? _stream;
  Float32List? _vertices;

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                _vertices != null ? Positioned.fill(
                  child: PcdView(
                    canvasSize: canvasSize, 
                    vertices: _vertices!,
                    backgroundColor: Colors.grey.shade600,
                    maxPointNum: 128000,
                  ),
                ) : const Center(child: Text("no data")),
              ],
            );
          }
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.live_tv),
          onPressed: () {
            if (_stream != null) return;
            final stream = api.captureHesai(address: "192.168.1.102:2368");
            stream.listen((event) {
              setState(() {
                _vertices = event.vertices;
              });
            });
          },
        ),
      );
  }
}
