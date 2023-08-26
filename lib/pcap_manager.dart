import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/bridge_definitions.dart';
import 'package:flutter_pcd/ffi.dart';
import 'package:uuid/uuid.dart';

class PcapManager extends ChangeNotifier {
  static int framesPerFragment = 8;
  
  Stream<PcdFrame>? _pcdStream;
  // final Map<int, PcdFragment> _cache = {};
  String localCachePath;
  // int nextFragmentKey = 0;
  late RandomAccessFile _readerFile;
  late RandomAccessFile _writerFile;
  List<int> frameStartOffsets = [];
  List<Float32List> points = [];
  
  int get length => frameStartOffsets.length;

  PcapManager(this.localCachePath);

  Future<bool> run(String pcapFile) async {
    try {
      final cacheFile = await File("$localCachePath/pcd_cache_${const Uuid().v4()}.bin");
      _writerFile = await cacheFile.open(mode: FileMode.writeOnlyAppend);
      _readerFile = await cacheFile.open(mode: FileMode.read);
      final stream = api.readPcapStream(path: pcapFile);
      setStream(stream);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  void setStream(Stream<PcdFrame> stream) {
    _pcdStream = stream;
    _pcdStream!.listen(_pcdListener);
  }

  @override
  void dispose() {
    _pcdStream?.listen(null);
    _pcdStream = null;
    _readerFile.close();
    _writerFile.close();
    super.dispose();
  }

  void _pcdListener(PcdFrame fragment) {
    Future(() async {
      try {
        final length = await _writerFile.length();
        await _writerFile.lock();
        await _writerFile.writeFrom(fragment.vertices.buffer.asUint8List());
        await _writerFile.unlock();
        frameStartOffsets.add(length);
        print(fragment.points.length);
        points.add(fragment.points);
        notifyListeners();
      } catch (e) {
        print(e);
      }
    });
  }

  Future<Float32List> operator [](int index) async {
    try {
      final offset = frameStartOffsets[index];
      final length = index + 1 < frameStartOffsets.length 
        ? frameStartOffsets[index + 1] - offset 
        : await _readerFile.length() - offset;
      await _readerFile.setPosition(offset);
      final buffer = Uint8List(length);
      await _readerFile.readInto(buffer);
      return Float32List.view(buffer.buffer);
    } catch (e) {
      print(e);
      return Float32List(0);
    }
  }
}