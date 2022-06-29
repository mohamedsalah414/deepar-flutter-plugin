import 'dart:async';

import 'package:camera/camera.dart';
import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'deep_ar_preview.dart';

class DeepAr {
  static int? textureId;
  static const MethodChannel _channel = MethodChannel('deep_ar');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> initialize(double width, double height) async {
    textureId = await _channel.invokeMethod('buildPreview', {
      'width': width,
      'height': height,
    });
    return textureId!;
  }
}
