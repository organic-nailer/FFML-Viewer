import 'package:flutter/material.dart';
import 'package:flutter_pcd/ui/screen/main_page/pcd_frame_notifier.dart';
import 'package:flutter_pcd/ui/theme/color_ext.dart';

class SolidAngleImageView extends StatelessWidget {
  final VoidCallback? onClose;
  const SolidAngleImageView({Key? key, this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frameNotifier = PcdFrameStateProvider.of(context, listen: true);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 192,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: getSurfaceContainerLowest(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (frameNotifier.solidAngleImage != null) Expanded(
                  child: Image.memory(
                      frameNotifier.solidAngleImage!,
                      fit: BoxFit.contain,
                      //filterQuality: FilterQuality.high,
                    ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Column(
                  children: [
                    IconButton(onPressed: () {
                      frameNotifier.isSolidAngleImageEnabled = false;
                      onClose?.call();
                    }, icon: const Icon(Icons.close)),
                  ],
                ),
              ],
            )
          ),
        ),
      ),
    );
  }
}
