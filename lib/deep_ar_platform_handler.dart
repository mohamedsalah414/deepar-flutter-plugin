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
}
