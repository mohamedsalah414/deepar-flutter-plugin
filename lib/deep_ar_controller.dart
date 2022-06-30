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
      // print("plane Y length ${image.planes[0].bytes.toList().length} ");
      // print("plane U length ${image.planes[1].bytes.toList().length} ");
      // print("plane V length ${image.planes[2].bytes.toList().length} ");
      // print("image height ${image.height}");
      // print("image width ${image.width}");
      if (sendFrames) {
        _deepArPlatformHandler
            .receiveFrame(image)
            .then((value) => print("frame receive result $value"));
        //sendFrames = false;
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
  Future<void> pausePreview() async {
    stopImageStream();
    // return super.pausePreview();
  }

  Future<String?> switchEffect(int effect) {
    return _deepArPlatformHandler.switchEffect(effect);
  }
}
