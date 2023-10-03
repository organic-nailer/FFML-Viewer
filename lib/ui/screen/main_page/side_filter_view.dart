import 'package:flutter/material.dart';
import 'package:flutter_pcd/ui/screen/main_page/side_filter_notifier.dart';
import 'package:flutter_pcd/ui/theme/color_ext.dart';

class SideFilterView extends StatelessWidget {
  final VoidCallback? onClose;
  const SideFilterView({Key? key, this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifier = SideFilterStateProvider.of(context, listen: true);
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
                            "Filter",
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        "distance_m ${notifier.filter.distance.start.toStringAsFixed(1)} - ${notifier.filter.distance.end.toStringAsFixed(1)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: RangeSlider(
                              values: notifier.filter.distance,
                              min: 0,
                              max: 300,
                              // divisions: 9,
                              onChanged: (value) {
                                notifier.setDistance(value);
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
                        "intensity ${notifier.filter.intensity.start.toStringAsFixed(1)} - ${notifier.filter.intensity.end.toStringAsFixed(1)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: RangeSlider(
                              values: notifier.filter.intensity,
                              min: 0,
                              max: 255,
                              // divisions: 9,
                              onChanged: (value) {
                                notifier.setIntensity(value);
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
                        "azimuth ${notifier.filter.azimuth.start.toStringAsFixed(1)} - ${notifier.filter.azimuth.end.toStringAsFixed(1)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: RangeSlider(
                              values: notifier.filter.azimuth,
                              min: 0,
                              max: 36000,
                              // divisions: 9,
                              onChanged: (value) {
                                notifier.setAzimuth(value);
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
                        "altitude ${notifier.filter.altitude.start.toStringAsFixed(1)} - ${notifier.filter.altitude.end.toStringAsFixed(1)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: RangeSlider(
                              values: notifier.filter.altitude,
                              min: -9000,
                              max: 9000,
                              // divisions: 9,
                              onChanged: (value) {
                                notifier.setAltitude(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
            ),
          )),
    );
  }
}
