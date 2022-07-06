import 'package:deep_ar/deep_ar_platform_handler.dart';
import 'package:flutter/material.dart';

class DeepArController {
  DeepArController() : super();
  final DeepArPlatformHandler _deepArPlatformHandler = DeepArPlatformHandler();
  int? textureId;

  bool get isInitialized => textureId != null;

  Future<void> initialize({required String licenseKey}) async {
    bool? isInitialized = await _deepArPlatformHandler.initialize(licenseKey);
    if (isInitialized != null && isInitialized) {
      textureId = await _deepArPlatformHandler.startCamera();
    }
  }

  Widget buildPreview() {
    return Texture(textureId: textureId!);
  }

  Future<String?> switchEffect(int effect) {
    return _deepArPlatformHandler.switchEffect(effect);
  }
}
