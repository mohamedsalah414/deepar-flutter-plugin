import 'package:deep_ar/platform_strings.dart';
import 'package:flutter/services.dart';

class DeepArCodec extends StandardMessageCodec {
  const DeepArCodec();
}

class DeepArPlatformHandler {
  static const MethodChannel _channel = MethodChannel(PlatformStrings.generalChannel);
  static const MethodChannel _cameraXChannel = MethodChannel(PlatformStrings.cameraXChannel);

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<bool?> initialize(String licenseKey, int width, int height) async {
    return await _channel.invokeMethod<bool?>(PlatformStrings.initialize, {
      PlatformStrings.licenseKey: licenseKey,
      "width": width,
      "height": height,
    });
  }

  Future<String?> switchEffect(int effect) {
    return _channel.invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<int> startCamera() async {
    int texturedId = await _cameraXChannel.invokeMethod(PlatformStrings.startCamera);
    // ignore: avoid_print
    print("TEXTURE_IDD $texturedId");
    return texturedId;
  }
}
