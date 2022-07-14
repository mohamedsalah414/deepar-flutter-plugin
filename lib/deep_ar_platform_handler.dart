import 'package:deep_ar/platform_strings.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:flutter/services.dart';

class DeepArCodec extends StandardMessageCodec {
  const DeepArCodec();
}

class DeepArPlatformHandler {
  static const MethodChannel _channel =
      MethodChannel(PlatformStrings.generalChannel);
  static const MethodChannel _cameraXChannel =
      MethodChannel(PlatformStrings.cameraXChannel);

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<String?> initialize(String licenseKey, Resolution resolution) {
    return _channel.invokeMethod<String?>(PlatformStrings.initialize, {
      PlatformStrings.licenseKey: licenseKey,
      "resolution": resolution.stringValue,
    });
  }

  Future<int> startCameraAndroid() async {
    int texturedId =
        await _cameraXChannel.invokeMethod(PlatformStrings.startCamera);
    return texturedId;
  }

  Future<Map<String, dynamic>?> startCameraIos() async {
    return await _channel
        .invokeMapMethod<String, dynamic>(PlatformStrings.startCamera);
  }

  Future<String?> switchEffect(String effect) {
    return _channel.invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<void> startRecordingVideo({String? filePath}) async {
    await _channel.invokeMethod(PlatformStrings.startRecordingVideo, {
      'file_path': filePath,
    });
  }

  Future<void> stopRecordingVideo() async {
    await _channel.invokeMethod(PlatformStrings.stopRecordingVideo);
  }

  Future<bool?> checkAllPermission() async {
    return await _channel
        .invokeMethod<bool?>(PlatformStrings.checkAllPermission);
  }

  Future<String?> checkVersion() async {
    return await _channel.invokeMethod<String?>(PlatformStrings.checkVersion);
  }

  Future<void> flipCamera() async {
    await _cameraXChannel.invokeMethod("flip_camera");
  }
}
