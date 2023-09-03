import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class PcdSlider extends StatefulWidget {
  final bool enabled;
  final int frameLength;
  final int selectedFrame;
  final Future Function(int value) onSelectedFrameChanged;

  const PcdSlider({
    Key? key,
    required this.selectedFrame,
    required this.frameLength,
    this.enabled = true,
    required this.onSelectedFrameChanged,
  }): assert(enabled ? frameLength > 0 : true), 
      assert(selectedFrame >= 0),
      assert(enabled ? selectedFrame < frameLength : true),
      super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PcdSliderState createState() => _PcdSliderState();
}

class _PcdSliderState extends State<PcdSlider> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _playAnimationController;
  Timer? _playTimer;

  @override
  void initState() {
    super.initState();
    _playAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _playAnimationController.dispose();
    _playTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.skip_previous_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: widget.enabled
              ? () async {
                  await widget.onSelectedFrameChanged(0);
                }
              : null,
          tooltip: "Back to first frame",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_circle_left_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: (widget.enabled && widget.selectedFrame > 0)
              ? () async {
                  await widget.onSelectedFrameChanged(widget.selectedFrame - 1);
                }
              : null,
          tooltip: "Previous frame",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _playAnimationController,
          ),
          color: Theme.of(context).colorScheme.primary,
          onPressed: widget.enabled
              ? () async {
                  if (_isPlaying) {
                    _playAnimationController.reverse();
                  } else {
                    _playAnimationController.forward();
                  }
                  _isPlaying = !_isPlaying;
                  if (_isPlaying) {
                    _playTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
                      if (widget.selectedFrame < widget.frameLength - 1) {
                        await widget.onSelectedFrameChanged(widget.selectedFrame + 1);
                      } else {
                        _playAnimationController.reverse();
                        _isPlaying = !_isPlaying;
                        timer.cancel();
                      }
                    });
                  } else {
                    _playTimer?.cancel();
                  }
                }
              : null,
          tooltip: "Pause",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_circle_right_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: (widget.enabled && widget.selectedFrame < widget.frameLength - 1)
              ? () async {
                  await widget.onSelectedFrameChanged(widget.selectedFrame + 1);
                }
              : null,
          tooltip: "Next frame",
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.skip_next_outlined),
          color: Theme.of(context).colorScheme.primary,
          onPressed: widget.enabled
              ? () async {
                  await widget.onSelectedFrameChanged(widget.frameLength - 1);
                }
              : null,
          tooltip: "Go to last frame",
        ),
        SizedBox(
          width: 96,
          child: TextField(
            controller: TextEditingController(text: widget.selectedFrame.toString()),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              suffixText: "/${widget.enabled ? widget.frameLength - 1 : 100}f",
            ),
            textAlign: TextAlign.end,
            textAlignVertical: TextAlignVertical.center,
            onSubmitted: (value) async {
              await widget.onSelectedFrameChanged(int.parse(value));
            },
            // style: const TextStyle(fontSize: 5),
          ),
        ),
        Expanded(
          child: Slider(
            value: widget.selectedFrame.toDouble(),
            min: 0,
            max: widget.enabled ? widget.frameLength - 1 : 100,
            divisions: widget.enabled ? max(widget.frameLength - 1, 1) : 100,
            onChanged: widget.enabled
                ? (value) async {
                    await widget.onSelectedFrameChanged(value.toInt());
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
