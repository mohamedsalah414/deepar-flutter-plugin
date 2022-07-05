import 'package:camera/camera.dart';
import 'package:deep_ar/deep_ar_platform_handler.dart';
import 'package:flutter/material.dart';

class DeepArController {
  DeepArController() : super();
  final DeepArPlatformHandler _deepArPlatformHandler = DeepArPlatformHandler();
  int? textureId;

  bool get isInitialized => textureId != null;

  Future<void> initialize() async {
    await _deepArPlatformHandler.initialize();
    await Future.delayed(Duration(seconds: 5));
    textureId = await _deepArPlatformHandler.startCamera();
    print("textureID $textureId");
  }

  bool sendFrames = true;

  Widget buildPreview() {
    // super.startImageStream((image) async {
    //   if (sendFrames) {
    //     _deepArPlatformHandler.receiveFrame(image);
    //   }
    // });

    return Texture(textureId: textureId!);
  }

  @override
  Future<void> startVideoRecording() async {
    // TODO: implement startVideoRecording
    // return super.startVideoRecording();
  }
  @override
  Future<void> resumePreview() async {
    // super.startImageStream((image) async {
    //   if (sendFrames) {
    //     _deepArPlatformHandler.receiveFrame(image);
    //   }
    // });
  }

  // Future<void> pausePreview() async {
  //   stopImageStream();
  //   // return super.pausePreview();
  // }

  Future<String?> switchEffect(int effect) {
    return _deepArPlatformHandler.switchEffect(effect);
  }
}
