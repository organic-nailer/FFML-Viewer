import 'dart:math';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcd/dialog/fast_color_picker.dart';
import 'package:flutter_pcd/pcap_manager.dart';
import 'package:flutter_pcd/pcd_view.dart';
import 'package:flutter_pcd/pcd_view/component/pcd_slider.dart';
import 'package:flutter_pcd/pcd_view/component/popup_text_button.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:path_provider/path_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Float32List _vertices;
  late Float32List _colors;
  late Float32List _masks;

  int counter = 0;
  double pointSize = 5;
  late TextEditingController _controller;
  SideState sideState = SideState.none;

  Color backgroundColor = Colors.grey;

  int selectedFrame = 0;
  int maxPointNum = 128000;
  PcapManager? _pcapManager;
  PcdDataSource _dataSource = PcdDataSource(Float32List(0), Float32List(0), Float32List(0));

  @override
  void initState() {
    super.initState();
    final cube = genCube(10);
    _vertices = cube.$1;
    _colors = cube.$2;
    _masks = cube.$3;
    _controller = TextEditingController(text: "$pointSize");
  }

  @override
  void dispose() {
    _controller.dispose();
    _pcapManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getSurfaceContainer(context),
      body: Builder(
        builder: (context) {
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    const typeGroup = XTypeGroup(
                                      label: "point cloud(xt32)",
                                      extensions: ["pcap"],
                                    );
                                    final file = await openFile(
                                        acceptedTypeGroups: [typeGroup]);
                                    if (file == null) {
                                      print("no file selected");
                                      return;
                                    }
                                    final path = file.path;
                                    final tempDir = await getTemporaryDirectory();
                                    _pcapManager?.dispose();
                                    _pcapManager = PcapManager(tempDir.path, maxPointNum);
                                    selectedFrame = 0;
                                    _pcapManager!.addListener(() async {
                                      if (_pcapManager!.length > 0 &&
                                          _dataSource.rowCount == 0) {
                                        final frame =
                                            await _pcapManager!.getFrame(0);
                                        if (frame == null) {
                                          print("failed to get frame");
                                          return;
                                        }
                                        _vertices = frame.vertices;
                                        _colors = frame.colors;
                                        _masks = frame.masks;
                                        _dataSource = PcdDataSource(
                                            _vertices, frame.otherData, frame.masks);
                                      }
                                      setState(() {});
                                    });
                                    final success = await _pcapManager!.run(path);
                                    if (!success) {
                                      print("failed to run pcap manager");
                                      return;
                                    }
                                  },
                                ),
                                TextButton(
                                  child: const Text("Edit"),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("Edit Button Is Not implemented"),
                                            behavior: SnackBarBehavior.floating,
                                            width: 500,
                                        ));
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
                                      enabled: _pcapManager != null,
                                      frameLength: _pcapManager?.length ?? 0,
                                      selectedFrame: selectedFrame,
                                      onSelectedFrameChanged: (value) async {
                                        if (value == selectedFrame) {
                                          // 複数回同じ値が来る可能性がある
                                          return;
                                        }
                                        selectedFrame = value;
                                        final frame =
                                            await _pcapManager!.getFrame(value);
                                        if (frame == null) {
                                          print("failed to get frame $value");
                                          return;
                                        }
                                        _vertices = frame.vertices;
                                        _colors = frame.colors;
                                        _masks = frame.masks;
                                        setState(() {});
                                        _dataSource = PcdDataSource(
                                            _vertices, frame.otherData, frame.masks);
                                        setState(() {});
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
                              vertices: _vertices,
                              colors: _colors,
                              masks: _masks,
                              maxPointNum: maxPointNum,
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 36,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 8),
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
                                              const SizedBox(width: 8,)
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
                                                  decoration: const InputDecoration(
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
                                                    padding:
                                                        const EdgeInsets.symmetric(
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
                                        const Divider(
                                          height: 1.0,
                                          thickness: 1.0,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              OutlinedButton(
                                                child: const Text("Update Cube"),
                                                onPressed: () {
                                                  setState(() {
                                                    final cube = genCube(
                                                        Random().nextInt(20) + 10);
                                                    _vertices = cube.$1;
                                                    _colors = cube.$2;
                                                    _masks = cube.$3;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      ]),
                                ),
                              )),
                        ),
                      if (sideState == SideState.table)
                        SizedBox(
                          width: 640,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: getSurfaceContainerLowest(context),
                                child: Column(
                                  children: [
                                        SizedBox(
                                          height: 36,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 8),
                                                child: Icon(
                                                  Icons.table_chart_rounded,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  size: 24,
                                                ),
                                              ),
                                              Text(
                                                "Table",
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
                                              const SizedBox(width: 8,)
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                          height: 1.0,
                                          thickness: 1.0,
                                        ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _dataSource.rowCount + 2,
                                        itemBuilder: (context, index) {
                                          if (index == 0) {
                                            return _dataSource.getHeader(context);
                                          }
                                          if (index == 1) {
                                            return const Divider(
                                              height: 1.0,
                                              thickness: 1.0,
                                            );
                                          }
                                          return _dataSource.getText(index - 2) ??
                                              const Text("-");
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        )
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
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

Color getSurfaceContainer(BuildContext context) {
  final seedColor = Theme.of(context).colorScheme.primary;
  final darkMode = Theme.of(context).colorScheme.brightness == Brightness.dark;
  CorePalette p = CorePalette.of(seedColor.value);
  return Color(p.neutral.get(darkMode ? 12 : 94));
}

Color getSurfaceContainerLowest(BuildContext context) {
  final seedColor = Theme.of(context).colorScheme.primary;
  final darkMode = Theme.of(context).colorScheme.brightness == Brightness.dark;
  CorePalette p = CorePalette.of(seedColor.value);
  return Color(p.neutral.get(darkMode ? 4 : 100));
}

enum SideState {
  none,
  settings,
  table,
}

class PcdDataSource extends DataTableSource {
  static const _columns = <(String, double)>[
    ("x", 48), // x
    ("y", 48), // y
    ("z", 48), // z
    ("adjustedtime", 96), // adjustedtime
    ("azimuth", 56), // azimuth
    ("distance_m", 72), // distance_m
    ("intensity", 72), // intensity
    ("laser_id", 64), // laser_id
    ("vertical_angle", 96), // vertical_angle
  ];

  // x y z
  final Float32List vertices;
  // reflectivity channel azimuth distance_m timestamp vertical_angle
  final Float32List others;
  final Float32List masks;

  int pointNum = 0;

  PcdDataSource(this.vertices, this.others, this.masks) {
    pointNum = masks.fold(0, (previousValue, element) => previousValue + element.toInt());
  }

  Widget getHeader(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _columns
            .map((e) => PcdDataHeader(e.$1, width: e.$2, color: primary))
            .toList(),
      ),
    );
  }

  Widget? getText(int index) {
    if (index >= vertices.length ~/ 3) {
      return null;
    }
    final xyz = vertices.sublist(index * 3, index * 3 + 3);
    final point = others.sublist(index * 6, index * 6 + 6);
    return ColoredBox(
      color: index % 2 == 0 ? Colors.black12 : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            PcdDataCell(xyz[0].toStringAsFixed(3), width: _columns[0].$2), // x
            PcdDataCell(xyz[1].toStringAsFixed(3), width: _columns[1].$2), // y
            PcdDataCell(xyz[2].toStringAsFixed(3), width: _columns[2].$2), // z
            PcdDataCell("${point[4].toInt()}",
                width: _columns[3].$2), // adjustedtime
            PcdDataCell("${point[2].toInt()}",
                width: _columns[4].$2), // azimuth
            PcdDataCell(point[3].toStringAsFixed(3),
                width: _columns[5].$2), // distance_m
            PcdDataCell("${point[0].toInt()}",
                width: _columns[6].$2), // intensity
            PcdDataCell("${point[1].toInt()}",
                width: _columns[7].$2), // laser_id
            PcdDataCell("${point[5].toInt()}",
                width: _columns[8].$2), // vertical_angle
          ],
        ),
      ),
    );
  }

  @override
  DataRow? getRow(int index) {
    dPrint("get row $index");
    if (index >= rowCount) {
      return null;
    }
    final xyz = vertices.sublist(index * 3, index * 3 + 3);
    final point = others.sublist(index * 6, index * 6 + 6);
    return DataRow.byIndex(index: index, cells: [
      DataCell(Text(xyz[0].toStringAsFixed(3))), // x
      DataCell(Text(xyz[1].toStringAsFixed(3))), // y
      DataCell(Text(xyz[2].toStringAsFixed(3))), // z
      DataCell(Text("${point[4].toInt()}")), // adjustedtime
      DataCell(Text("${point[2].toInt()}")), // azimuth
      DataCell(Text(point[3].toStringAsFixed(3))), // distance_m
      DataCell(Text("${point[0].toInt()}")), // intensity
      DataCell(Text("${point[1].toInt()}")), // laser_id
      DataCell(Text("${point[5].toInt()}")), // vertical_angle
    ]);
  }

  @override
  int get rowCount => pointNum;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class PcdDataCell extends StatelessWidget {
  final String text;
  final double width;

  const PcdDataCell(this.text, {Key? key, required this.width})
      : super(key: key);

  static const cellTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: cellTextStyle,
        textAlign: TextAlign.end,
      ),
    );
  }
}

class PcdDataHeader extends StatelessWidget {
  final String text;
  final double width;
  final Color color;

  const PcdDataHeader(this.text,
      {Key? key, required this.width, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cellTextStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: color,
    );
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: cellTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
