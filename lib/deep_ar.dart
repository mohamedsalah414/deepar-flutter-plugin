import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class PreviewWidget extends StatefulWidget {
  const PreviewWidget({Key? key}) : super(key: key);

  @override
  State<PreviewWidget> createState() => _PreviewWidgetState();
}

class _PreviewWidgetState extends State<PreviewWidget> {
  @override
  void initState() {
    DeepAr.initialize(200, 200).then((value) => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DeepAr.textureId != null
        ? SizedBox(
            height: 200,
            width: 200,
            child: Texture(textureId: DeepAr.textureId!),
          )
        : Container(
            height: 100,
            width: 100,
            color: Colors.green,
          );
  }
}
