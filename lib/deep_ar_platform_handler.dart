import 'dart:async';
import 'dart:io';

import 'package:deep_ar/deep_ar_controller.dart';
import 'package:deep_ar/platform_strings.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:flutter/services.dart';

class DeepArPlatformHandler {
  static const MethodChannel _channel =
      MethodChannel(PlatformStrings.generalChannel);
  static const MethodChannel _cameraXChannel =
      MethodChannel(PlatformStrings.cameraXChannel);
  MethodChannel _avCameraChannel(int view) =>
      MethodChannel(PlatformStrings.avCameraChannel + "/$view");

  late final void Function(DeepArNativeResponse response,
      {String? message, dynamic data}) onNativeResponse;

  static String? _videoFilePath = "N/A";

  DeepArPlatformHandler() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(listenFromNativeMethodHandler);
    }
  }

  void setListener(int view) {
    _avCameraChannel(view).setMethodCallHandler(listenFromNativeMethodHandler);
  }

  Future<void> listenFromNativeMethodHandler(MethodCall call) async {
    switch (call.method) {
      case "on_video_result":
        Map<dynamic, dynamic> data = call.arguments;
        //bool status = data['status'] ?? false;

        String caller = data['caller'];
        String? filePath = data['file_path'];
        String message = data['message'] ?? "";

        // isSuccess or isFail

        DeepArNativeResponse response =
            DeepArNativeResponse.values.byName(caller);

        print("WAITTT : $caller => $filePath");

        if (response == DeepArNativeResponse.videoCompleted) {
          _videoFilePath = filePath;
        } else {
          _videoFilePath = null;
        }
        //isVideoResult = true;

        //onNativeResponse(response, message: message, data: filePath);
        break;
      default:
        print('no method handler for method ${call.method}');
    }
  }

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

  Future<String?> switchEffectAndroid(String effect) {
    return _channel.invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<String?> switchCameraIos(String effect, int view) {
    return _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<void> startRecordingVideoAndroid() async {
    await _channel.invokeMethod(PlatformStrings.startRecordingVideo);
  }

  Future<File?> stopRecordingVideoAndroid() async {
    _channel.invokeMethod(PlatformStrings.stopRecordingVideo);

    await Future.delayed(const Duration(seconds: 1));
    print("file_path : $_videoFilePath");
    return File(_videoFilePath!);
  }

  Future<void> startRecordingVideoIos(int view) async {
    await _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.startRecordingVideo);
  }

  Future<File?> stopRecordingVideoIos(int view) async {
    _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.stopRecordingVideo);

    await Future.delayed(const Duration(seconds: 1));
    print("file_path : $_videoFilePath");
    return File(_videoFilePath!);
  }

  Future<bool?> checkAllPermission() async {
    return await _channel
        .invokeMethod<bool?>(PlatformStrings.checkAllPermission);
  }

  Future<String?> getResolutionDimensions(int view) async {
    final dimensions = await _avCameraChannel(view)
        .invokeMethod<String?>(PlatformStrings.getResolution);
    return dimensions;
  }

  Future<bool?> flipCamera() {
    return _cameraXChannel.invokeMethod<bool>("flip_camera");
  }

  Future<bool?> flipCameraIos(int view) {
    return _avCameraChannel(view).invokeMethod<bool>("flip_camera");
  }

  Future<File?> takeScreenShot() async {
    await _cameraXChannel.invokeMethod("take_screenshot");
  }

  Future<File?> takeScreenShotIos(int view) async {
    await _avCameraChannel(view).invokeMethod<String>("take_screenshot");
  }

  Future<bool> toggleFlash() async {
    return await _cameraXChannel.invokeMethod<bool>("toggle_flash") ?? false;
  }

  Future<bool> toggleFlashIos(int view) async {
    return await _avCameraChannel(view).invokeMethod<bool>("toggle_flash") ??
        false;
  }
}
