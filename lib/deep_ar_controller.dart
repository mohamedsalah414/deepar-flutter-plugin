import 'dart:io';
import 'dart:math';
import 'package:deep_ar/deep_ar_platform_handler.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:flutter/material.dart';

class DeepArController {
  DeepArController() : super();
  final DeepArPlatformHandler _deepArPlatformHandler = DeepArPlatformHandler();
  int? textureId;
  late Resolution resolution;

  bool get isInitialized => textureId != null;
  late bool isPermission;

  Future<void> initialize(
      {required String licenseKey,
      required Resolution preset,
      required int width,
      required int height}) async {
    resolution = preset;

    isPermission = await _deepArPlatformHandler.checkAllPermission() ?? false;
    if (isPermission) {
      bool? isInitialized =
          await _deepArPlatformHandler.initialize(licenseKey, width, height);
      if (isInitialized != null && isInitialized) {
        textureId = await _deepArPlatformHandler.startCamera();
      }
    }
  }

  Widget buildPreview() {
    return Texture(textureId: textureId!);
  }

  Future<String?> switchEffect(int effect) {
    return _deepArPlatformHandler.switchEffect(effect);
  }

  Future<void> startVideoRecording() async {
    //final Directory directory = await getApplicationDocumentsDirectory();
    Directory dir = Directory('/storage/emulated/0/Download');
    var r = Random();

    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
    // Radom filename for now
    String fileName =
        List.generate(5, (index) => _chars[r.nextInt(_chars.length)]).join();
    final File file = File('${dir.path}/$fileName.mp4');
    await file.create();
    _deepArPlatformHandler.startRecordingVideo(file.path);
  }

  void stopVideoRecording() {
    _deepArPlatformHandler.stopRecordingVideo();
  }
}
