import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/bridge_definitions.dart';
import 'package:flutter_pcd/ffi.dart';
import 'package:uuid/uuid.dart';

class PcapManager extends ChangeNotifier {
  static int framesPerFragment = 8;
  
  Stream<PcdFragment>? _pcdStream;
  // final Map<int, PcdFragment> _cache = {};
  String localCachePath;
  // int nextFragmentKey = 0;
  late RandomAccessFile _readerFile;
  late RandomAccessFile _writerFile;
  List<int> frameStartOffsets = [];
  
  int get length => frameStartOffsets.length;

  PcapManager(this.localCachePath);

  Future<bool> run(String pcapFile) async {
    try {
      final cacheFile = await File("$localCachePath/pcd_cache_${const Uuid().v4()}.bin");
      _writerFile = await cacheFile.open(mode: FileMode.writeOnlyAppend);
      _readerFile = await cacheFile.open(mode: FileMode.read);
      final stream = api.readPcapStream(path: pcapFile, framesPerFragment: framesPerFragment);
      setStream(stream);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  void setStream(Stream<PcdFragment> stream) {
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

  void _pcdListener(PcdFragment fragment) {
    Future(() async {
      final length = await _writerFile.length();
      await _writerFile.lock();
      await _writerFile.writeFrom(fragment.vertices.buffer.asUint8List());
      await _writerFile.unlock();
      frameStartOffsets.addAll(fragment.frameStartIndices.map((e) => e * 4 + length));
      notifyListeners();
    });
  }

  Float32List operator [](int index) {
    final offset = frameStartOffsets[index];
    final length = index + 1 < frameStartOffsets.length 
      ? frameStartOffsets[index + 1] - offset 
      : _readerFile.lengthSync() - offset;
    _readerFile.setPositionSync(offset);
    final buffer = Uint8List(length);
    _readerFile.readIntoSync(buffer);
    return Float32List.view(buffer.buffer);
  }
}