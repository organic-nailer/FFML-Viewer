import 'package:flutter/material.dart';
import 'package:flutter_pcd/dialog/fast_color_picker.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_appearance_notifier.dart';
import 'package:flutter_pcd/ui/theme/color_ext.dart';

class SideSettingsView extends StatefulWidget {
  final VoidCallback? onClose;
  const SideSettingsView({Key? key, this.onClose}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _SideSettingsViewState createState() => _SideSettingsViewState();
}

class _SideSettingsViewState extends State<SideSettingsView> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: "");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = PcdAppearanceStateProvider.of(context);
    _controller.text = "${notifier.pointSize}";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = PcdAppearanceStateProvider.of(context, listen: true);
    return SizedBox(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Icon(
                              Icons.settings,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          Text(
                            "Settings",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onClose,
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text("1",
                              style: Theme.of(context).textTheme.bodyMedium),
                          Expanded(
                            child: Slider(
                              value: notifier.pointSize,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (value) {
                                notifier.setPointSize(value);
                              },
                            ),
                          ),
                          Text("10",
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(
                            width: 16,
                          ),
                          SizedBox(
                            width: 72,
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSubmitted: (value) {
                                try {
                                  final size = double.parse(value);
                                  notifier.setPointSize(size);
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Material(
                      child: InkWell(
                        child: SizedBox(
                          height: 56,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: CircleAvatar(
                                  backgroundColor: notifier.backgroundColor,
                                ),
                              ),
                              Text(
                                "#${notifier.backgroundColor.value.toRadixString(16).substring(2).toUpperCase()}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        onTap: () async {
                          final selectedColor = await FastColorPicker.show(
                              context, notifier.backgroundColor, false);
                          if (selectedColor != null) {
                            notifier.setBackgroundColor(selectedColor);
                          }
                        },
                      ),
                    ),
                  ]),
            ),
          )),
    );
  }
}
