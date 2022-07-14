import 'dart:io';

import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/material.dart';

class DeepArPreview extends StatelessWidget {
  const DeepArPreview(this.deepArController, {Key? key}) : super(key: key);
  final DeepArController deepArController;

  @override
  Widget build(BuildContext context) {
    return deepArController.isInitialized
        ? AspectRatio(
            aspectRatio: Platform.isAndroid
                ? (1 / deepArController.aspectRatio)
                : deepArController.aspectRatio,
            child: Platform.isAndroid
                ? deepArController.buildPreview()
                : _DeepArIosPreview(deepArController),
          )
        : Container();
  }
}

class _DeepArIosPreview extends StatefulWidget {
  final DeepArController deepArController;
  const _DeepArIosPreview(this.deepArController, {Key? key}) : super(key: key);

  @override
  State<_DeepArIosPreview> createState() => __DeepArIosPreviewState();
}

class __DeepArIosPreviewState extends State<_DeepArIosPreview> {
  @override
  Widget build(BuildContext context) {
    return widget.deepArController.isInitialized
        ? AspectRatio(
            aspectRatio: Platform.isAndroid
                ? (1 / widget.deepArController.aspectRatio)
                : widget.deepArController.aspectRatio,
            child: widget.deepArController.buildPreview(oniOSViewCreated: () {
              setState(() {});
            }),
          )
        : Container();
  }
}
