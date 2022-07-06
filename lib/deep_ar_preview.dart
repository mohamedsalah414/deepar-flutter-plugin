import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/material.dart';

class DeepArPreview extends StatelessWidget {
  final DeepArController deepArController;
  final Widget? child;
  const DeepArPreview(this.deepArController, {this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return deepArController.isInitialized
        ? Stack(
            fit: StackFit.expand,
            children: <Widget>[
              SizedBox(height: 720, child: deepArController.buildPreview()),
              child ?? Container(),
            ],
          )
        : Container();
  }
}
