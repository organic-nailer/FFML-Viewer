import 'package:flutter/material.dart';
import 'package:flutter_pcd/ui/pcd_view/component/pcd_slider.dart';
import 'package:flutter_pcd/ui/pcd_view/component/popup_text_button.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_frame_notifier.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_state.dart';

class PcdToolHeader extends StatelessWidget {
  final SideState currentSideState;
  final ValueChanged<SideState>? onSideStateChanged;
  const PcdToolHeader({Key? key, required this.currentSideState, this.onSideStateChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frameNotifier = PcdFrameStateProvider.of(context, listen: true);
    return SizedBox(
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
                          onSideStateChanged?.call(SideState.filter);
                        },
                      ),
                      TextButton(
                        child: const Text("View"),
                        onPressed: () {
                          onSideStateChanged?.call(SideState.none);
                        },
                      ),
                      TextButton(
                        child: const Text("Table"),
                        onPressed: () {
                          onSideStateChanged?.call(SideState.table);
                        },
                      ),
                      TextButton(
                        child: const Text("Settings"),
                        onPressed: () {
                          onSideStateChanged?.call(SideState.settings);
                        },
                      ),
                      PopupTextButton<String>(
                        text: "Help",
                        offset: const Offset(0, -32),
                        items: const [
                          PopupMenuItem(value: "about", child: Text("About")),
                          PopupMenuItem(
                              value: "license", child: Text("License")),
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
                            frameLength: frameNotifier.isEnabled
                                ? frameNotifier.frameCount
                                : 0,
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
    );
  }
}
