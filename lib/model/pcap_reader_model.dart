import 'package:flutter/foundation.dart';
import 'package:flutter_pcd/domain/pcd_filter.dart';
import 'package:flutter_pcd/model/pcap_manager.dart';
import 'package:path_provider/path_provider.dart';

abstract class PcapReaderModel {
  Future<void> openNewFile(String path, int maxPointNum);
  Future<void> closeFile();
  Future<DisplayPcdFrame> getFrame(int index, {PcdFilter? filter});
  int getFrameCount();
  void addListener(VoidCallback listener);
  bool get isEnabled;
}

class PcapReaderModelImpl implements PcapReaderModel {
  PcapManager? _pcapManager;
  VoidCallback? _listener;

  PcapReaderModelImpl();

  @override
  bool get isEnabled => _pcapManager != null;

  @override
  Future<void> openNewFile(String path, int maxPointNum) async {
    _pcapManager?.dispose();
    final tempDir = await getTemporaryDirectory();
    _pcapManager = PcapManager(tempDir.path, maxPointNum)..run(path);
    if (_listener != null) {
      _pcapManager?.addListener(_listener!);
    }
  }

  @override
  Future<void> closeFile() async {
    _pcapManager?.dispose();
    if (_listener != null) {
      _pcapManager?.removeListener(_listener!);
    }
    _pcapManager = null;
  }

  @override
  Future<DisplayPcdFrame> getFrame(int index, {PcdFilter? filter}) async {
    assert(_pcapManager != null, "pcap manager is null");
    final frame = await _pcapManager!.getFrame(index, filter: filter);
    if (frame != null) {
      return frame;
    } else {
      throw Exception("frame is null");
    }
  }

  @override
  int getFrameCount() {
    assert(_pcapManager != null, "pcap manager is null");
    return _pcapManager!.length;
  }

  @override
  void addListener(VoidCallback listener) {
    _listener = listener;
    _pcapManager?.addListener(listener);
  }
}
