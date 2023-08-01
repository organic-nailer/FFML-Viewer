import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/bridge_definitions.dart';
import 'package:flutter_pcd/ffi.dart';

class PcapManager extends ChangeNotifier {
  static int framesPerFragment = 8;
  
  Stream<PcdFragment>? _pcdStream;
  final Map<int, PcdFragment> _cache = {};
  String localCachePath;
  int nextFragmentKey = 0;

  int get length => nextFragmentKey - 1;

  PcapManager(this.localCachePath, String filePath,) {
    final stream = api.readPcapStream(path: filePath, framesPerFragment: framesPerFragment);
    setStream(stream);
  }

  void setStream(Stream<PcdFragment> stream) {
    _pcdStream = stream;
    _pcdStream!.listen(_pcdListener);
  }

  @override
  void dispose() {
    _pcdStream?.listen(null);
    _pcdStream = null;
    super.dispose();
  }

  void _pcdListener(PcdFragment fragment) {
    print("pcdListener: ${fragment.frameStartIndices}");
    _cache[nextFragmentKey] = fragment;
    final frames = fragment.frameStartIndices.length;
    nextFragmentKey += frames;
    // print("pcdListener: ${fragment.frameNum}");
    notifyListeners();
  }

  Float32List operator [](int index) {
    final fragmentIndex = (index ~/ framesPerFragment) * framesPerFragment;
    final frameIndex = index % framesPerFragment;
    final fragment = _cache[fragmentIndex];
    if (fragment == null) {
      print(_cache.keys);
      print(fragmentIndex);
      throw Exception();
    }
    final frameStartIndex = fragment.frameStartIndices[frameIndex];
    final frameEndIndex = frameIndex == framesPerFragment - 1 
      ? fragment.vertices.length
      : fragment.frameStartIndices[frameIndex + 1];
    print(index);
    return fragment.vertices.sublist(frameStartIndex, frameEndIndex);
  }
}