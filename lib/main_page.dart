import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/dialog/fast_color_picker.dart';
import 'package:flutter_pcd/pcd_view.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Float32List _vertices;
  int counter = 0;
  double pointSize = 5;
  late TextEditingController _controller;
  SideState sideState = SideState.none;

  Color backgroundColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _vertices = genCube(10);
    _controller = TextEditingController(text: "$pointSize");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getSurfaceContainer(context),
      body: Column(
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
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          "Flutter Point Cloud Demo",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Flexible(
                          child: Row(
                        children: [
                          TextButton(
                            child: const Text("File"),
                            onPressed: () {},
                          ),
                          TextButton(
                            child: const Text("Edit"),
                            onPressed: () {},
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
                          TextButton(
                            child: const Text("Help"),
                            onPressed: () {},
                          ),
                        ],
                      )),
                    ],
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
                          // colors: _colors.toDartList(),
                          maxPointNum: 29 * 29 * 29,
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
                                      height: 56,
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
                                              size: 32,
                                            ),
                                          ),
                                          Text(
                                            "Settings",
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
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
                                                _vertices = genCube(
                                                    Random().nextInt(20) + 10);
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
                            child: SingleChildScrollView(
                              child: PaginatedDataTable(
                                showCheckboxColumn: false,
                                rowsPerPage: 100,
                                columns: PcdDataSource.columns,
                                source: PcdDataSource(),
                              ),
                            ),
                          )),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Float32List genCube(int sidePts) {
  // x y z
  final result = Float32List(sidePts * sidePts * sidePts * 6);
  for (var x = 0; x < sidePts; x++) {
    for (var y = 0; y < sidePts; y++) {
      for (var z = 0; z < sidePts; z++) {
        final index = x * sidePts * sidePts + y * sidePts + z;
        result[index * 6 + 0] = x / (sidePts - 1) - 0.5;
        result[index * 6 + 1] = y / (sidePts - 1) - 0.5;
        result[index * 6 + 2] = z / (sidePts - 1) - 0.5;
        result[index * 6 + 3] = x / (sidePts - 1);
        result[index * 6 + 4] = y / (sidePts - 1);
        result[index * 6 + 5] = z / (sidePts - 1);
      }
    }
  }
  return result;
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
  static const columns = [
    DataColumn(label: Text("x")),
    DataColumn(label: Text("y")),
    DataColumn(label: Text("z")),
    DataColumn(label: Text("adjustedtime")),
    DataColumn(label: Text("azimuth")),
    DataColumn(label: Text("distance_m")),
    DataColumn(label: Text("intensity")),
    DataColumn(label: Text("laser_id")),
    DataColumn(label: Text("vertical_angle")),
  ];

  @override
  DataRow? getRow(int index) {
    return DataRow(cells: [
      DataCell(Text("x")),
      DataCell(Text("y")),
      DataCell(Text("z")),
      DataCell(Text("x")),
      DataCell(Text("y")),
      DataCell(Text("z")),
      DataCell(Text("x")),
      DataCell(Text("y")),
      DataCell(Text("z")),
    ]);
  }

  @override
  int get rowCount => 99;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
