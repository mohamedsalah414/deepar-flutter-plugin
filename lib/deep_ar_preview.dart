import 'dart:io';

import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/material.dart';

class DeepArPreview extends StatefulWidget {
  const DeepArPreview(this.deepArController, this.onViewCreated, {Key? key})
      : super(key: key);
  final DeepArController deepArController;

  final VoidCallback  onViewCreated;

  @override
  State<DeepArPreview> createState() => _DeepArPreviewState();
}

class _DeepArPreviewState extends State<DeepArPreview> {
  @override
  Widget build(BuildContext context) {
    return widget.deepArController.isInitialized
        ? Platform.isAndroid
            ? widget.deepArController.buildPreview(onViewCreated: () {
                widget.onViewCreated();
              })
            : widget.deepArController.buildPreview(onViewCreated: () {
                widget.onViewCreated();
                setState(() {});
              })
        : Container();
  }
}

// class _DeepArIosPreview extends StatefulWidget {
//   final DeepArController deepArController;
//   const _DeepArIosPreview(this.deepArController, {Key? key}) : super(key: key);

//   @override
//   State<_DeepArIosPreview> createState() => __DeepArIosPreviewState();
// }

// class __DeepArIosPreviewState extends State<_DeepArIosPreview> {
//   @override
//   Widget build(BuildContext context) {
//     return widget.deepArController.buildPreview(oniOSViewCreated: () {
//       setState(() {});
//     });
//   }
// }
