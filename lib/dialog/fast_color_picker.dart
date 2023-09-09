import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class FastColorPicker extends StatefulWidget {
  static Future<Color?> show(
      BuildContext context, Color recentColor, bool useAlpha) async {
    return showDialog<Color>(
      context: context,
      builder: (context) =>
          FastColorPicker(color: recentColor, useAlpha: useAlpha),
    );
  }

  const FastColorPicker({Key? key, required this.color, this.useAlpha = false})
      : super(key: key);

  final Color color;
  final bool useAlpha;

  @override
  _FastColorPickerState createState() => _FastColorPickerState();
}

class _FastColorPickerState extends State<FastColorPicker> {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a color!'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _color,
          enableAlpha: widget.useAlpha,
          onColorChanged: (color) => setState(() => _color = color),
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Got it'),
          onPressed: () {
            Navigator.of(context).pop(_color);
          },
        ),
      ],
    );
  }
}
