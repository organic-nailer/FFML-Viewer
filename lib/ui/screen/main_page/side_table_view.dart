import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcd/common/dprint.dart';
import 'package:flutter_pcd/ui/theme/color_ext.dart';

class SideTableView extends StatelessWidget {
  final VoidCallback? onClose;
  final PcdDataSource dataSource;
  const SideTableView({Key? key, this.onClose, required this.dataSource})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Icon(
                          Icons.table_chart_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      Text(
                        "Table",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
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
                Expanded(
                  child: ListView.builder(
                    itemCount: dataSource.rowCount + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return dataSource.getHeader(context);
                      }
                      if (index == 1) {
                        return const Divider(
                          height: 1.0,
                          thickness: 1.0,
                        );
                      }
                      return dataSource.getText(index - 2) ?? const Text("-");
                    },
                  ),
                ),
              ],
            ),
          )),
    );
  }
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
    pointNum = masks.fold(
        0, (previousValue, element) => previousValue + element.toInt());
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
