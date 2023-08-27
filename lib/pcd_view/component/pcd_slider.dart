import 'package:flutter/material.dart';
import 'package:flutter_pcd/pcap_manager.dart';

class PcdSlider extends StatelessWidget {
  final PcapManager? _pcapManager;
  final int selectedFrame;
  final Future Function(int value) onSelectedFrameChanged;

  const PcdSlider({
    Key? key,
    required PcapManager? pcapManager,
    required this.selectedFrame,
    required this.onSelectedFrameChanged,
  })  : _pcapManager = pcapManager,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.skip_previous_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: _pcapManager != null
              ? () async {
                  await onSelectedFrameChanged(0);
                }
              : null,
          tooltip: "Back to first frame",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_circle_left_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: _pcapManager != null
              ? () async {
                  await onSelectedFrameChanged(selectedFrame - 1);
                }
              : null,
          tooltip: "Previous frame",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.pause_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: _pcapManager != null
              ? () async {
                  await onSelectedFrameChanged(selectedFrame);
                }
              : null,
          tooltip: "Pause",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_circle_right_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: _pcapManager != null
              ? () async {
                  await onSelectedFrameChanged(selectedFrame + 1);
                }
              : null,
          tooltip: "Next frame",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.skip_next_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: _pcapManager != null
              ? () async {
                  await onSelectedFrameChanged(_pcapManager!.length - 1);
                }
              : null,
          tooltip: "Go to last frame",
        ),
        SizedBox(
          width: 96,
          child: TextField(
            controller: TextEditingController(text: selectedFrame.toString()),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              suffixText: "/${_pcapManager != null ? _pcapManager!.length - 1 : 100}f",
            ),
            textAlign: TextAlign.end,
            textAlignVertical: TextAlignVertical.center,
            onSubmitted: (value) async {
              await onSelectedFrameChanged(int.parse(value));
            },
            // style: const TextStyle(fontSize: 5),
          ),
        ),
        Expanded(
          child: Slider(
            value: selectedFrame.toDouble(),
            min: 0,
            max: _pcapManager != null ? _pcapManager!.length - 1 : 100,
            divisions: _pcapManager != null ? _pcapManager!.length - 1 : 100,
            onChanged: _pcapManager != null
                ? (value) async {
                    await onSelectedFrameChanged(value.toInt());
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
