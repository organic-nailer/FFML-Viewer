import 'package:flutter/material.dart';
import 'package:flutter_pcd/ui/screen/main_page/bottom_state.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_state.dart';

class SideToolRail extends StatelessWidget {
  final SideState sideState;
  final BottomState bottomState;
  final ValueChanged<SideState>? onSideStateChanged;
  final ValueChanged<BottomState>? onBottomStateChanged;
  const SideToolRail(
      {Key? key,
      required this.sideState,
      required this.bottomState,
      this.onSideStateChanged,
      this.onBottomStateChanged})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          IconButton(
            onPressed: () {
              if (sideState == SideState.settings) {
                onSideStateChanged?.call(SideState.none);
              } else {
                onSideStateChanged?.call(SideState.settings);
              }
            },
            isSelected: sideState == SideState.settings,
            tooltip: "Settings",
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () {
              if (bottomState == BottomState.image) {
                onBottomStateChanged?.call(BottomState.none);
              } else {
                onBottomStateChanged?.call(BottomState.image);
              }
            },
            isSelected: bottomState == BottomState.image,
            tooltip: "Image",
            icon: const Icon(Icons.image_outlined),
            selectedIcon: const Icon(Icons.image),
          ),
          IconButton(
            onPressed: () {
              if (sideState == SideState.table) {
                onSideStateChanged?.call(SideState.none);
              } else {
                onSideStateChanged?.call(SideState.table);
              }
            },
            isSelected: sideState == SideState.table,
            tooltip: "Table",
            icon: const Icon(Icons.table_chart_outlined),
            selectedIcon: const Icon(Icons.table_chart),
          ),
          IconButton(
            onPressed: () {
              if (sideState == SideState.filter) {
                onSideStateChanged?.call(SideState.none);
              } else {
                onSideStateChanged?.call(SideState.filter);
              }
            },
            isSelected: sideState == SideState.filter,
            tooltip: "Filter",
            icon: const Icon(Icons.filter_alt_outlined),
            selectedIcon: const Icon(Icons.filter_alt),
          ),
        ],
      ),
    );
  }
}
