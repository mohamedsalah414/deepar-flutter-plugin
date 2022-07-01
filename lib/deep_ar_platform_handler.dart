import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:deep_ar/platform_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeepArCodec extends StandardMessageCodec {
  const DeepArCodec();
}

class DeepArPlatformHandler {
  static const MethodChannel _channel = MethodChannel('deep_ar');
  static const BasicMessageChannel _framesChannel =
      BasicMessageChannel("deep_ar/frames", BinaryCodec());

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> initialize() async {
    await _channel.invokeMethod(PlatformStrings.initalize);
  }

  Future<int?> buildPreview() async {
    return _channel.invokeMethod<int>(PlatformStrings.buildPreview, {
      'width': 1080,
      'height': 1920,
    });
  }

  Future<int?> receiveFrame(CameraImage image) async {
    //add data to buffer. v and u are swapped intentionally
    WriteBuffer buffer = WriteBuffer();
    buffer.putUint8List(image.planes[0].bytes);
    buffer.putUint8List(image.planes[2].bytes);
    buffer.putUint8List(image.planes[1].bytes);
    await _framesChannel.send(buffer.done());
    return 0;
  }

  Future<String?> switchEffect(int effect) {
    return _channel.invokeMethod<String>(PlatformStrings.switchEffect, {
      'effect': effect,
    });
  }
}
