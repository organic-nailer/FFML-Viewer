import 'package:flutter/material.dart';

class PopupTextButton<T> extends StatefulWidget {
  final String text;
  final List<PopupMenuItem<T>> items;
  final Offset? offset;
  final void Function(T value)? onSelected;

  const PopupTextButton({
    Key? key,
    required this.text,
    required this.items,
    this.offset,
    this.onSelected,
  }) : super(key: key);

  @override
  _PopupTextButtonState<T> createState() => _PopupTextButtonState<T>();
}

class _PopupTextButtonState<T> extends State<PopupTextButton<T>> {

  Future<T?> _showButtonMenu() {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      (widget.offset ?? Offset.zero) & overlay.size,
    );
    return showMenu(
      context: context,
      position: position,
      items: widget.items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        final T? value = await _showButtonMenu();
        if (value != null && widget.onSelected != null) {
          widget.onSelected!(value);
        }
      },
      child: Text(widget.text),
    );
  }
}
