import 'dart:io';
import 'dart:math';
import 'package:deep_ar/deep_ar_platform_handler.dart';
import 'package:deep_ar/platform_strings.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';

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
  String? _iosLicenseKey;
  Future<void> initialize(
      {String? androidLicenseKey,
      String? iosLicenseKey,
      required Resolution preset}) async {
    assert(androidLicenseKey != null || iosLicenseKey != null,
        "Both android and iOS license keys cannot be null");

    _iosLicenseKey = iosLicenseKey;
    resolution = preset;
    isPermission = await _deepArPlatformHandler.checkAllPermission() ?? false;
    print("PERMISSSION : $isPermission");
    //if (!isPermission) return;

    if (Platform.isAndroid) {
      assert(androidLicenseKey != null, "androidLicenseKey missing");
      String? dimensions =
          await _deepArPlatformHandler.initialize(androidLicenseKey!, preset);
      if (dimensions != null) {
        double width = double.parse(dimensions.split(" ")[0]);
        double height = double.parse(dimensions.split(" ")[1]);
        _aspectRatio = width / height;
        textureId = await _deepArPlatformHandler.startCameraAndroid();
      }
    } else if (Platform.isIOS) {
      assert(iosLicenseKey != null, "iosLicenseKey missing");
      //TODO: Try to predict size before intialization
      size = const Size(500, 500);
      _aspectRatio = size!.width / size!.height;
      textureId = -1;
    } else {
      throw ("Platform not supported");
    }
  }

  Widget buildPreview({Function()? oniOSViewCreated}) {
    if (Platform.isAndroid) {
      return Texture(textureId: textureId!);
    } else if (Platform.isIOS) {
      return UiKitView(
          viewType: "deep_ar_view",
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            PlatformStrings.licenseKey: _iosLicenseKey,
            PlatformStrings.resolution: resolution.stringValue
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: ((id) {
            textureId = id;
            _deepArPlatformHandler
                .getResolutionDimensions(textureId!)
                .then((value) {
              _aspectRatio = value!.width / value.height;
              oniOSViewCreated?.call();
            });
          }));
    } else {
      throw ("Platform not supported.");
    }
  }

  Future<String?> switchEffect(String effect) {
    return _deepArPlatformHandler.switchEffect(effect, textureId!);
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
      _deepArPlatformHandler.startRecordingVideoIos(textureId!);
    }
  }

  void stopVideoRecording() {
    if (Platform.isAndroid) {
      _deepArPlatformHandler.stopRecordingVideo();
    } else {
      _deepArPlatformHandler.stopRecordingVideoIos(textureId!);
    }
  }

  void flipCamera() {
    if (Platform.isAndroid) {
      _deepArPlatformHandler.flipCamera();
    } else {
      _deepArPlatformHandler.flipCameraIos(textureId!);
    }
  }

  void takeScreenshot() {
    if (Platform.isAndroid) {
      _deepArPlatformHandler.takeScreenShot();
    } else {
      _deepArPlatformHandler.takeScreenShotIos(textureId!);
    }
  }

  Future<bool> toggleFlash() {
    if (Platform.isAndroid) {
      return _deepArPlatformHandler.toggleFlash();
    } else {
      return _deepArPlatformHandler.toggleFlashIos(textureId!);
    }
  }

  Future<String?> checkVersion() {
    return _deepArPlatformHandler.checkVersion();
  }

  Size toSize(Map<dynamic, dynamic> data) {
    final width = data['width'];
    final height = data['height'];
    return Size(width, height);
  }

  Future<bool> askMediaPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.storage,
    ].request();

    if (await Permission.camera.isGranted &&
        await Permission.microphone.isGranted &&
        await Permission.storage.isGranted) {
      return true;
    }

    return false;
  }
}
