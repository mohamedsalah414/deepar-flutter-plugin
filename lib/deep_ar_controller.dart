import 'dart:io';
import 'dart:math';
import 'package:deep_ar/deep_ar_platform_handler.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:flutter/material.dart';

class DeepArController {
  DeepArController() : super();
  final DeepArPlatformHandler _deepArPlatformHandler = DeepArPlatformHandler();
  int? textureId;
  Size? size;
  double? height;
  double? width;
  double _aspectRatio = 1.0;
  late Resolution resolution;

  bool get isInitialized => textureId != null;
  bool isPermission = false;
  double get aspectRatio => _aspectRatio;

  Future<void> initialize(
      {required String licenseKey, required Resolution preset}) async {
    resolution = preset;
    isPermission = await _deepArPlatformHandler.checkAllPermission() ?? false;
    if (isPermission) {
      if (Platform.isAndroid) {
        // Android
        String? dimensions =
            await _deepArPlatformHandler.initialize(licenseKey, preset);
        if (dimensions != null) {
          double width = double.parse(dimensions.split(" ")[0]);
          double height = double.parse(dimensions.split(" ")[1]);
          _aspectRatio = width / height;
          textureId = await _deepArPlatformHandler.startCameraAndroid();
        }
      } else {
        // iOS
        String? response =
            await _deepArPlatformHandler.initialize(licenseKey, preset);
        if (response == "Initialized") {
          final mapData = await _deepArPlatformHandler.startCameraIos();
          textureId = mapData?['textureId'];
          size = toSize(mapData?['size']);
          _aspectRatio = size!.width / size!.height;
        }
      }

      print("TEXTURE_ID : $textureId");
    }
  }

  Widget buildPreview() {
    return Texture(textureId: textureId!);
  }

  Future<String?> switchEffect(String effect) {
    return _deepArPlatformHandler.switchEffect(effect);
  }

  Future<void> startVideoRecording() async {
    if (Platform.isAndroid) {
      Directory dir = Directory('/storage/emulated/0/Download');
      var r = Random();

      const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
      // Radom filename for now
      String fileName =
          List.generate(5, (index) => _chars[r.nextInt(_chars.length)]).join();
      final File file = File('${dir.path}/$fileName.mp4');
      await file.create();
      _deepArPlatformHandler.startRecordingVideo(filePath: file.path);
    } else {
      _deepArPlatformHandler.startRecordingVideo();
    }
  }

  void stopVideoRecording() {
    _deepArPlatformHandler.stopRecordingVideo();
  }

  Future<String?> checkVersion() {
    return _deepArPlatformHandler.checkVersion();
  }

  Size toSize(Map<dynamic, dynamic> data) {
    final width = data['width'];
    final height = data['height'];
    return Size(width, height);
  }
}
