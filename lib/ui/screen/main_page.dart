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
import 'package:flutter_pcd/ui/screen/main_page/pcd_frame_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_view.dart';
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
  @override
  void initState() {
    super.initState();
    _filterNotifier = SideFilterNotifier();
    _frameNotifier = PcdFrameNotifier(
      PcapReaderModelImpl(),
      _filterNotifier
    );
  }

  @override
  Widget build(BuildContext context) {
    print("build main page");
    return SideFilterStateProvider(
      notifier: _filterNotifier,
      child: PcdFrameStateProvider(
        notifier: _frameNotifier,
        child: const _MainPageInternal()
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
  // late Float32List _vertices;
  // late Float32List _colors;
  // late Float32List _masks;

  int counter = 0;
  double pointSize = 5;
  late TextEditingController _controller;
  SideState sideState = SideState.none;

  Color backgroundColor = Colors.grey;

  // int selectedFrame = 0;
  // int maxPointNum = 128000;
  // PcapManager? _pcapManager;
  // PcdDataSource _dataSource =
  //     PcdDataSource(Float32List(0), Float32List(0), Float32List(0));

  @override
  void initState() {
    super.initState();
    // final cube = genCube(10);
    // _vertices = cube.$1;
    // _colors = cube.$2;
    // _masks = cube.$3;
    _controller = TextEditingController(text: "$pointSize");
  }

  @override
  void dispose() {
    _controller.dispose();
    // _pcapManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterNotifier = SideFilterStateProvider.of(context, listen: true);
    final frameNotifier = PcdFrameStateProvider.of(context, listen: true);
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
                            backgroundColor: backgroundColor,
                            pointSize: pointSize,
                          );
                        }),
                      ),
                    ),
                    if (sideState != SideState.none)
                      const SizedBox(
                        width: 16,
                      ),
                    if (sideState == SideState.settings)
                      SizedBox(
                        width: 320,
                        height: double.infinity,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: getSurfaceContainerLowest(context),
                              child: SingleChildScrollView(
                                child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 36,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              child: Icon(
                                                Icons.settings,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 24,
                                              ),
                                            ),
                                            Text(
                                              "Settings",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () {
                                                setState(() {
                                                  sideState = SideState.none;
                                                });
                                              },
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            )
                                          ],
                                        ),
                                      ),
                                      const Divider(
                                        height: 1.0,
                                        thickness: 1.0,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Text(
                                          "Point Size",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            Text("1",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium),
                                            Expanded(
                                              child: Slider(
                                                value: pointSize,
                                                min: 1,
                                                max: 10,
                                                divisions: 9,
                                                onChanged: (value) {
                                                  setState(() {
                                                    pointSize = value;
                                                    _controller.text =
                                                        "$pointSize";
                                                  });
                                                },
                                              ),
                                            ),
                                            Text("10",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium),
                                            const SizedBox(
                                              width: 16,
                                            ),
                                            SizedBox(
                                              width: 72,
                                              child: TextField(
                                                controller: _controller,
                                                decoration:
                                                    const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onSubmitted: (value) {
                                                  try {
                                                    setState(() {
                                                      pointSize =
                                                          double.parse(value)
                                                              .floorToDouble()
                                                              .clamp(1, 10);
                                                      _controller.text =
                                                          "$pointSize";
                                                    });
                                                  } catch (e) {
                                                    print(e);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Text(
                                          "Background Color",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      Material(
                                        child: InkWell(
                                          child: SizedBox(
                                            height: 56,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        backgroundColor,
                                                  ),
                                                ),
                                                Text(
                                                  "#${backgroundColor.value.toRadixString(16).substring(2).toUpperCase()}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () async {
                                            final selectedColor =
                                                await FastColorPicker.show(
                                                    context,
                                                    backgroundColor,
                                                    false);
                                            if (selectedColor != null) {
                                              setState(() {
                                                backgroundColor = selectedColor;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ]),
                              ),
                            )),
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

(Float32List, Float32List, Float32List) genCube(int sidePts) {
  // x y z
  final vertices = Float32List(sidePts * sidePts * sidePts * 3);
  // r g b
  final colors = Float32List(sidePts * sidePts * sidePts * 3);

  final masks = Float32List(sidePts * sidePts * sidePts);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        vertices[index * 3 + 0] = x / (sidePts - 1) - 0.5;
        vertices[index * 3 + 1] = y / (sidePts - 1) - 0.5;
        vertices[index * 3 + 2] = z / (sidePts - 1) - 0.5;
        colors[index * 3 + 0] = x / (sidePts - 1);
        colors[index * 3 + 1] = y / (sidePts - 1);
        colors[index * 3 + 2] = z / (sidePts - 1);
        masks[index] = 1;
      }
    }
  }
  return (vertices, colors, masks);
}

enum SideState {
  none,
  settings,
  table,
  filter,
}
