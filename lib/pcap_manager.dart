import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/bridge_definitions.dart';
import 'package:flutter_pcd/ffi.dart';
import 'package:flutter_pcd/resource_cleaner/resource_cleaner.dart';
import 'package:uuid/uuid.dart';

class PcapManager extends ChangeNotifier with Cleanable {
  static int framesPerFragment = 8;
  
  StreamSubscription<PcdFrame>? _pcdStreamSubscription;
  // final Map<int, PcdFragment> _cache = {};
  String localCachePath;
  // int nextFragmentKey = 0;
  late File _cacheFile;
  late RandomAccessFile _readerFile;
  late RandomAccessFile _writerFile;
  List<int> frameStartOffsets = [];
  List<Float32List> points = [];
  
  int get length => frameStartOffsets.length;

  PcapManager(this.localCachePath) {
    registerToClean();
  }

  Future<bool> run(String pcapFile) async {
    try {
      _cacheFile = File("$localCachePath/pcd_cache_${const Uuid().v4()}.bin");
      _writerFile = await _cacheFile.open(mode: FileMode.writeOnlyAppend);
      _readerFile = await _cacheFile.open(mode: FileMode.read);
      final stream = api.readPcapStream(path: pcapFile);
      setStream(stream);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  void setStream(Stream<PcdFrame> stream) {
    _pcdStreamSubscription?.cancel();
    _pcdStreamSubscription = null;
    _pcdStreamSubscription = stream.listen(_pcdListener);
  }

  @override
  void dispose() {
    clean();
    super.dispose();
  }

  @override
  Future<void> clean() async {
    // await _pcdStreamSubscription?.cancel();
    await _readerFile.close();
    await _writerFile.close();
    await _cacheFile.delete();
    print("pcap manager files disposed");
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