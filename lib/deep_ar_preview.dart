import 'package:deep_ar/deep_ar_controller.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:flutter/material.dart';

class DeepArPreview extends StatelessWidget {
  final DeepArController deepArController;
  final Widget? child;
  const DeepArPreview(this.deepArController, {this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return deepArController.isInitialized
        ? AspectRatio(
            aspectRatio: deepArController.aspectRatio,
            child: deepArController.buildPreview(),
          )
        : Container();
  }
}
