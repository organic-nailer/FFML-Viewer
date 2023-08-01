import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class StoreFilePage extends StatefulWidget {
  const StoreFilePage({Key? key}) : super(key: key);

  @override
  _StoreFilePageState createState() => _StoreFilePageState();
}

class _StoreFilePageState extends State<StoreFilePage> {
  String? _tempDirPath;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store File'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Store File',
            ),
            TextButton(
              onPressed: () async {
                final tempDir = await getTemporaryDirectory();
                final dir = await tempDir.createTemp("flutter_pcd");
                _tempDirPath = dir.path;
                final file = File('${dir.path}/test.bin');

                final data = Float32List(1000*1000*100);
                for (var i = 0; i < data.length; i++) {
                  data[i] = i.toDouble();
                }
                final stopwatch = Stopwatch()..start();
                await file.writeAsBytes([1,2,3,4,5,6,7,8,9,10]);
                await file.writeAsBytes(data.buffer.asUint8List(), mode: FileMode.append);
                print('writeAsBytes: ${stopwatch.elapsedMilliseconds} ms');
              },
              child: const Text('Store File'),
            ),
            TextButton(
              onPressed: () async {
                if (_tempDirPath != null) {
                  final stopwatch = Stopwatch()..start();
                  final file = File('$_tempDirPath/test.bin');
                  final data = await file.readAsBytes();
                  print("data[:10]: ${data.sublist(0, 10)}");
                  print('readAsBytes: ${stopwatch.elapsedMilliseconds} ms');
                }
                else {
                  print('No file');
                }
              },
              child: const Text('Read File'),
            )
          ],
        ),
      ),
    );
  }
}
