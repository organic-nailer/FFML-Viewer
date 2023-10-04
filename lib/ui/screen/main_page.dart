import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/model/pcap_reader_model.dart';
import 'package:flutter_pcd/ui/pcd_view/pcd_view.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_appearance_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_frame_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_tool_header.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_view.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_settings_view.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_table_view.dart';
import 'package:flutter_pcd/ui/theme/color_ext.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  late final SideFilterNotifier _filterNotifier;
  late final PcdFrameNotifier _frameNotifier;
  late final PcdAppearanceNotifier _appearanceNotifier;
  @override
  void initState() {
    super.initState();
    _filterNotifier = SideFilterNotifier();
    _frameNotifier = PcdFrameNotifier(PcapReaderModelImpl(), _filterNotifier);
    _appearanceNotifier = PcdAppearanceNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return SideFilterStateProvider(
      notifier: _filterNotifier,
      child: PcdFrameStateProvider(
          notifier: _frameNotifier,
          child: PcdAppearanceStateProvider(
              notifier: _appearanceNotifier, child: const _MainPageInternal())),
    );
  }
}

class _MainPageInternal extends StatefulWidget {
  const _MainPageInternal({Key? key}) : super(key: key);

  @override
  State<_MainPageInternal> createState() => _MainPageInternalState();
}

class _MainPageInternalState extends State<_MainPageInternal> {
  SideState sideState = SideState.none;

  @override
  Widget build(BuildContext context) {
    final frameNotifier = PcdFrameStateProvider.of(context, listen: true);
    final appearanceNotifier =
        PcdAppearanceStateProvider.of(context, listen: true);
    return Scaffold(
      backgroundColor: getSurfaceContainer(context),
      body: Builder(builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PcdToolHeader(
              currentSideState: sideState,
              onSideStateChanged: (state) {
                setState(() {
                  sideState = state;
                });
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final canvasSize =
                              Size(constraints.maxWidth, constraints.maxHeight);
                          return PcdView(
                            canvasSize: canvasSize,
                            vertices:
                                frameNotifier.frame?.vertices ?? Float32List(0),
                            colors:
                                frameNotifier.frame?.colors ?? Float32List(0),
                            masks: frameNotifier.mask ?? Float32List(0),
                            maxPointNum: 128000,
                            backgroundColor: appearanceNotifier.backgroundColor,
                            pointSize: appearanceNotifier.pointSize,
                          );
                        }),
                      ),
                    ),
                    if (sideState != SideState.none)
                      const SizedBox(
                        width: 16,
                      ),
                    if (sideState == SideState.settings)
                      SideSettingsView(
                        onClose: () {
                          setState(() {
                            sideState = SideState.none;
                          });
                        },
                      ),
                    if (sideState == SideState.table)
                      SideTableView(
                        dataSource: frameNotifier.frame != null
                            ? PcdDataSource(
                                frameNotifier.frame!.vertices,
                                frameNotifier.frame!.colors,
                                frameNotifier.mask!,
                              )
                            : PcdDataSource(
                                Float32List(0), Float32List(0), Float32List(0)),
                        onClose: () {
                          setState(() {
                            sideState = SideState.none;
                          });
                        },
                      ),
                    if (sideState == SideState.filter)
                      SideFilterView(
                        onClose: () {
                          setState(() {
                            sideState = SideState.none;
                          });
                        },
                      )
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

enum SideState {
  none,
  settings,
  table,
  filter,
}
