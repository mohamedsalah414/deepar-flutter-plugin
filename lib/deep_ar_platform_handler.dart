import 'package:camera/camera.dart';
import 'package:deep_ar/platform_strings.dart';
import 'package:flutter/services.dart';

class DeepArPlatformHandler {
  static const MethodChannel _channel = MethodChannel('deep_ar');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> initialize() async {
    await _channel.invokeMethod(PlatformStrings.initalize);
  }

  Future<int?> buildPreview() async {
    return _channel.invokeMethod<int>(PlatformStrings.buildPreview, {
      'width': 1200,
      'height': 3000,
    });
  }

  Future<int?> receiveFrame(CameraImage image) async {
    return _channel.invokeMethod<int>(PlatformStrings.receiveFrame, {
      "y_plane": image.planes[0].bytes,
      "u_plane": image.planes[1].bytes,
      "v_plane": image.planes[2].bytes,
      "image_height": image.height,
      "image_width": image.width,
      "pixel_stride": image.planes[1].bytesPerPixel
    });
  }
}
