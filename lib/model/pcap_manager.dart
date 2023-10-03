import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/bridge_definitions.dart';
import 'package:flutter_pcd/common/dprint.dart';
import 'package:flutter_pcd/domain/pcd_filter.dart';
import 'package:flutter_pcd/ffi.dart';
import 'package:flutter_pcd/resource_cleaner/resource_cleaner.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';

class PcapManager extends ChangeNotifier with Cleanable {
  static int framesPerFragment = 8;

  StreamSubscription<PcdFrame>? _pcdStreamSubscription;
  // final Map<int, PcdFragment> _cache = {};
  String localCachePath;
  // int nextFragmentKey = 0;
  late _BinFileCache _vFileCache;
  late _BinFileCache _cFileCache;
  late _BinFileCache _oFileCache;

  late Float32List _throughMask;

  int get length => min(
      _vFileCache.length,
      min(
        _cFileCache.length,
        _oFileCache.length,
      ));

  PcapManager(this.localCachePath, int maxPointNum) {
    registerToClean();
    _throughMask = Float32List(maxPointNum);
    for (var i = 0; i < maxPointNum; i++) {
      _throughMask[i] = 1.0;
    }
  }

  Future<bool> run(String pcapFile) async {
    try {
      _vFileCache =
          _BinFileCache(localCachePath, debug: true, onUpdate: notifyListeners);
      _cFileCache = _BinFileCache(localCachePath, onUpdate: notifyListeners);
      _oFileCache = _BinFileCache(localCachePath, onUpdate: notifyListeners);
      await (
        _vFileCache.start(),
        _cFileCache.start(),
        _oFileCache.start(),
      ).wait;
      final stream = api.readPcapStream(path: pcapFile);
      setStream(stream);
      return true;
    } catch (e) {
      print("pcap manager run error: $e");
      if (e is ParallelWaitError) {
        print(e.errors);
      }
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
    await (
      _vFileCache.dispose(),
      _cFileCache.dispose(),
      _oFileCache.dispose(),
    ).wait;
    print("pcap manager files disposed");
  }

  void _pcdListener(PcdFrame fragment) {
    Future(() async {
      try {
        await (
          _vFileCache.add(fragment.vertices),
          _cFileCache.add(fragment.colors),
          _oFileCache.add(fragment.otherData),
        ).wait;
        // notifyListeners();
      } catch (e) {
        print("pcap manager listener error: $e");
        if (e is ParallelWaitError) {
          print(e.errors);
        }
      }
    });
  }

  Future<DisplayPcdFrame?> getFrame(int index, {bool onlyVertices = false, PcdFilter? filter}) async {
    try {
      if (onlyVertices) {
        final (vertices, colors) = await (
          _vFileCache[index],
          _cFileCache[index],
        ).wait;
        if (vertices == null || colors == null) return null;
        final pointsNum = vertices.length ~/ 3;
        return DisplayPcdFrame(
            vertices: vertices, 
            colors: colors, 
            otherData: Float32List(0),
            pointNum: pointsNum,
            frameIndex: index
        );
      } else {
        final (vertices, colors, otherData) = await (
          _vFileCache[index],
          _cFileCache[index],
          _oFileCache[index],
        ).wait;
        if (vertices == null || colors == null || otherData == null) {
          return null;
        }
        return DisplayPcdFrame(
            vertices: vertices, 
            colors: colors, 
            otherData: otherData,
            pointNum: vertices.length ~/ 3,
            frameIndex: index
        );
      }
    } catch (e) {
      print("pcap manager get frame error: $e");
      if (e is ParallelWaitError) {
        print(e.errors);
      }
      return null;
    }
  }
}

typedef FutureFunc = Future<void> Function();

class _BinFileCache {
  late final File _file;
  late final RandomAccessFile _reader;
  late final RandomAccessFile _writer;
  late final List<int> _offsets = [];
  final String _dir;
  CancelableOperation? _readOperation;
  final List<FutureFunc> _writeQueue = [];
  final void Function()? onUpdate;
  final bool debug;

  _BinFileCache(this._dir, {this.debug = false, this.onUpdate});

  int get length => _offsets.length;

  Future<void> start() async {
    _file = File("$_dir/pcd_cache_${const Uuid().v4()}.bin");
    _writer = await _file.open(mode: FileMode.writeOnlyAppend);
    _reader = await _file.open(mode: FileMode.read);
  }

  Future<void> add(Float32List data) async {
    if (debug) dPrint("add data: ${data.length}, ${_writeQueue.length}");
    if (_writeQueue.isEmpty) {
      _writeQueue.add(() async {
        await _add(data);
      });
      await _cleanQueue();
    } else {
      if (debug) dPrint("add to queue: ${_writeQueue.length}");
      _writeQueue.add(() async {
        await _add(data);
      });
    }
  }

  Future<void> _add(Float32List data) async {
    if (debug) dPrint("write: ${_offsets.length}");
    final length = await _writer.length();
    await _writer.writeFrom(data.buffer.asUint8List());
    _offsets.add(length);
    onUpdate?.call();
  }

  Future<void> _cleanQueue() async {
    if (debug) dPrint("clean queue: ${_writeQueue.length}");
    // assert(_operation != null);
    assert(_writeQueue.isNotEmpty);
    await _writeQueue[0]();
    _writeQueue.removeAt(0);
    if (_writeQueue.isNotEmpty) {
      await _cleanQueue();
    }
  }

  Future<Float32List?> operator [](int index) async {
    if (_readOperation == null || _readOperation!.isCompleted) {
      _readOperation = CancelableOperation.fromFuture(_getItem(index));
      return await _readOperation!.value;
    } else {
      if (debug) dPrint("read failed: ${_readOperation!.value}");
      return null;
    }
  }

  Future<Float32List?> _getItem(int index) async {
    try {
      final offset = _offsets[index];
      final length = index + 1 < _offsets.length
          ? _offsets[index + 1] - offset
          : await _reader.length() - offset;
      await _reader.setPosition(offset);
      final buffer = Uint8List(length);
      await _reader.readInto(buffer);
      return Float32List.view(buffer.buffer);
    } catch (e) {
      print(e);
      if (e is Error) {
        print(e.stackTrace);
      }
      return null;
    }
  }

  Future<void> dispose() async {
    await _reader.close();
    await _writer.close();
    await _file.delete();
  }
}

class DisplayPcdFrame {
  final Float32List vertices;
  final Float32List colors;
  final Float32List otherData;
  final int pointNum;
  final int frameIndex;

  DisplayPcdFrame(
      {required this.vertices,
      required this.colors,
      required this.otherData,
      required this.pointNum,
      required this.frameIndex});
}