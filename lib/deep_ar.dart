import 'dart:async';

import 'package:flutter/services.dart';

export 'deep_ar_preview.dart';

class DeepAr {
  static int? textureId;
  static const MethodChannel _channel = MethodChannel('deep_ar');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
