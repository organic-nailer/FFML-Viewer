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
  Stream<PcdFrame>? _stream;
  Float32List? _vertices;

  int _pointSize = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            _vertices != null
                ? Positioned.fill(
                    child: PcdView(
                      canvasSize: canvasSize,
                      vertices: _vertices!,
                      colors: Float32List(_vertices!.length),
                      masks: Float32List(_vertices!.length),
                      backgroundColor: Colors.grey.shade600,
                      maxPointNum: 128000,
                      pointSize: _pointSize.toDouble(),
                    ),
                  )
                : const Center(child: Text("no data")),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      child: const Text("-"),
                      onPressed: () {
                        setState(() {
                          _pointSize = (_pointSize - 1).clamp(1, 10);
                        });
                      },
                    ),
                    Text("$_pointSize"),
                    ElevatedButton(
                      child: const Text("+"),
                      onPressed: () {
                        setState(() {
                          _pointSize = (_pointSize + 1).clamp(1, 10);
                        });
                      },
                    ),
                  ],
                )),
          ],
        );
      }),
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
