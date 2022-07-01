import 'package:camera/camera.dart';
import 'package:deep_ar/deep_ar_platform_handler.dart';
import 'package:flutter/material.dart';

class DeepArController extends CameraController {
  DeepArController(CameraDescription description, ResolutionPreset preset)
      : super(description, preset, imageFormatGroup: ImageFormatGroup.yuv420);
  final DeepArPlatformHandler _deepArPlatformHandler = DeepArPlatformHandler();
  int? textureId;
  @override
  Future<void> initialize() async {
    await super.initialize();
    await _deepArPlatformHandler.initialize();
    textureId = await _deepArPlatformHandler.buildPreview();
    print("textureID $textureId");
  }

  bool sendFrames = true;
  @override
  Widget buildPreview() {
    super.startImageStream((image) async {
      if (sendFrames) {
        _deepArPlatformHandler.receiveFrame(image);
      }
    });

    return Texture(textureId: textureId!);
  }

  @override
  Future<void> startVideoRecording() async {
    // TODO: implement startVideoRecording
    // return super.startVideoRecording();
  }
  @override
  Future<void> resumePreview() async {
    super.startImageStream((image) async {
      if (sendFrames) {
        _deepArPlatformHandler.receiveFrame(image);
      }
    });
  }

  @override
  Future<void> pausePreview() async {
    stopImageStream();
    // return super.pausePreview();
  }

  Future<String?> switchEffect(int effect) {
    return _deepArPlatformHandler.switchEffect(effect);
  }
}
