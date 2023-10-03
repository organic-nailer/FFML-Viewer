import 'dart:math';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcd/dialog/fast_color_picker.dart';
import 'package:flutter_pcd/model/pcap_manager.dart';
import 'package:flutter_pcd/model/pcap_reader_model.dart';
import 'package:flutter_pcd/ui/pcd_view/pcd_view.dart';
import 'package:flutter_pcd/ui/pcd_view/component/pcd_slider.dart';
import 'package:flutter_pcd/ui/pcd_view/component/popup_text_button.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_appearance_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_frame_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_view.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_settings_view.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_table_view.dart';
import 'package:flutter_pcd/ui/theme/color_ext.dart';
import 'package:path_provider/path_provider.dart';

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
    _frameNotifier = PcdFrameNotifier(
      PcapReaderModelImpl(),
      _filterNotifier
    );
    _appearanceNotifier = PcdAppearanceNotifier();
  }

  @override
  Widget build(BuildContext context) {
    print("build main page");
    return SideFilterStateProvider(
      notifier: _filterNotifier,
      child: PcdFrameStateProvider(
        notifier: _frameNotifier,
        child: PcdAppearanceStateProvider(
          notifier: _appearanceNotifier,
          child: const _MainPageInternal()
        )
      ),
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
    final appearanceNotifier = PcdAppearanceStateProvider.of(context, listen: true);
    return Scaffold(
      backgroundColor: getSurfaceContainer(context),
      body: Builder(builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CircleAvatar(
                        backgroundImage: AssetImage("assets/circleCSG.png"),
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: Text(
                              "FFML Viewer",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Flexible(
                              child: Row(
                            children: [
                              TextButton(
                                child: const Text("File"),
                                onPressed: () async {
                                  final result = await frameNotifier.selectPcapFile();
                                  if (!result) {
                                    print("failed to select pcap file");
                                    return;
                                  }
                                },
                              ),
                              TextButton(
                                child: const Text("Filter"),
                                onPressed: () {
                                  setState(() {
                                    sideState = SideState.filter;
                                  });
                                },
                              ),
                              TextButton(
                                child: const Text("View"),
                                onPressed: () {
                                  setState(() {
                                    sideState = SideState.none;
                                  });
                                },
                              ),
                              TextButton(
                                child: const Text("Table"),
                                onPressed: () {
                                  setState(() {
                                    sideState = SideState.table;
                                  });
                                },
                              ),
                              TextButton(
                                child: const Text("Settings"),
                                onPressed: () {
                                  setState(() {
                                    sideState = SideState.settings;
                                  });
                                },
                              ),
                              PopupTextButton<String>(
                                text: "Help",
                                offset: Offset(0, -32),
                                items: const [
                                  PopupMenuItem(
                                      child: Text("About"), value: "about"),
                                  PopupMenuItem(
                                      child: Text("License"), value: "license"),
                                ],
                                onSelected: (value) {
                                  if (value == "about") {
                                    showAboutDialog(
                                      context: context,
                                      applicationIcon: const CircleAvatar(
                                        backgroundImage:
                                            AssetImage("assets/circleCSG.png"),
                                      ),
                                      applicationName: "FFML Viewer",
                                      applicationVersion: "0.0.1",
                                      applicationLegalese: "© 2021 CircleCSG",
                                    );
                                  } else if (value == "license") {
                                    showLicensePage(
                                      context: context,
                                      applicationName: "FFML Viewer",
                                      applicationVersion: "0.0.1",
                                      applicationLegalese: "© 2021 CircleCSG",
                                    );
                                  }
                                },
                              ),
                              Expanded(
                                child: PcdSlider(
                                    enabled: frameNotifier.isEnabled,
                                    frameLength: frameNotifier.isEnabled ? frameNotifier.frameCount : 0,
                                    selectedFrame: frameNotifier.frame?.frameIndex ?? 0,
                                    onSelectedFrameChanged: (value) async {
                                      if (value == frameNotifier.frame?.frameIndex) {
                                        // 複数回同じ値が来る可能性がある
                                        return;
                                      }
                                      frameNotifier.requestFrame(value);
                                    }),
                              )
                            ],
                          )),
                        ],
                      ),
                    ),
                  )
                ],
              ),
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
                            vertices: frameNotifier.frame?.vertices ?? Float32List(0),
                            colors: frameNotifier.frame?.colors ?? Float32List(0),
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
                          : PcdDataSource(Float32List(0), Float32List(0), Float32List(0)),
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
