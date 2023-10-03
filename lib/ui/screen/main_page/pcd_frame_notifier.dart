import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcd/model/pcap_manager.dart';
import 'package:flutter_pcd/model/pcap_mask_builder.dart';
import 'package:flutter_pcd/model/pcap_reader_model.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_notifier.dart';

class PcdFrameNotifier extends ChangeNotifier {
  final PcapReaderModel _pcapReaderModel;
  final SideFilterNotifier _filterNotifier;
  final PcapMaskBuilder _maskBuilder = PcapMaskBuilder();

  Future<void>? _updateFrameFuture;

  PcdFrameNotifier(this._pcapReaderModel, this._filterNotifier) {
    _filterNotifier.addListener(_rebuildMask);
    _pcapReaderModel.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _filterNotifier.removeListener(_rebuildMask);
    super.dispose();
  }

  Future<bool> selectPcapFile() async {
    const typeGroup = XTypeGroup(
      label: "point cloud(xt32)",
      extensions: ["pcap"],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) {
      print("no file selected");
      return false;
    }
    final path = file.path;
    await _pcapReaderModel.openNewFile(path, 128000);
    return true;
  }

  DisplayPcdFrame? _frame;
  DisplayPcdFrame? get frame => _frame;
  Float32List? _mask;
  Float32List? get mask => _mask;

  bool get isEnabled => _pcapReaderModel.isEnabled;

  int get frameCount => _pcapReaderModel.getFrameCount();

  void requestFrame(int index) {
    if (_updateFrameFuture != null) {
      print("frame update is in progress: $index");
      return;
    }
    _updateFrameFuture = Future(() async {
      final frame = await _pcapReaderModel.getFrame(
        index,
        filter: _filterNotifier.filter,
      );
      _frame = frame;
      _mask = _maskBuilder.buildMask(frame, _filterNotifier.filter);
      notifyListeners();
    }).then(
      (value) => _updateFrameFuture = null,
      onError: (error, stackTrace) {
        print("request frame error: $error");
        print(stackTrace);
        _updateFrameFuture = null;
      },
    );
  }

  void _rebuildMask() {
    if (_frame == null) return;
    _mask = _maskBuilder.buildMask(_frame!, _filterNotifier.filter);
    notifyListeners();
  }
}

class PcdFrameStateProvider extends InheritedNotifier<PcdFrameNotifier> {
  static PcdFrameNotifier of(BuildContext context, {bool listen = false}) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<PcdFrameStateProvider>()!
          .notifier!;
    } else {
      return (context
              .getElementForInheritedWidgetOfExactType<PcdFrameStateProvider>()!
              .widget as PcdFrameStateProvider)
          .notifier!;
    }
  }

  const PcdFrameStateProvider(
      {super.key, required super.child, required super.notifier})
      : super();
}
