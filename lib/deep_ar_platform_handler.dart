import 'dart:async';
import 'dart:io';

import 'package:deep_ar/platform_strings.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum VideoResponse { videoStarted, videoCompleted, videoError }

enum ScreenshotResponse { screenshotTaken }

class DeepArPlatformHandler {
  static const MethodChannel _channel =
      MethodChannel(PlatformStrings.generalChannel);
  static const MethodChannel _cameraXChannel =
      MethodChannel(PlatformStrings.cameraXChannel);
  MethodChannel _avCameraChannel(int view) =>
      MethodChannel(PlatformStrings.avCameraChannel + "/$view");
  static VideoResponse? _videoResponse;
  static String? _videoFilePath;
  static ScreenshotResponse? _screenshotResponse;
  static String? _screenshotFilePath;

  DeepArPlatformHandler() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(listenFromNativeMethodHandler);
    }
  }

  void setListenerIos(int view) {
    _avCameraChannel(view).setMethodCallHandler(listenFromNativeMethodHandler);
  }

  Future<void> listenFromNativeMethodHandler(MethodCall call) async {
    Map<dynamic, dynamic> data = call.arguments;

    String caller = data['caller'];
    String? filePath = data['file_path'];
    String _ = data['message'] ?? "";
    switch (call.method) {
      case "on_video_result":
        _videoResponse = VideoResponse.values.byName(caller);

        if (_videoResponse == VideoResponse.videoCompleted) {
          _videoFilePath = filePath;
        } else {
          _videoFilePath = null;
        }

        break;
      case "on_screenshot_result":
        _screenshotResponse = ScreenshotResponse.values.byName(caller);

        if (_screenshotResponse == ScreenshotResponse.screenshotTaken) {
          _screenshotFilePath = filePath;
        } else {
          _screenshotFilePath = null;
        }

        break;
      default:
        debugPrint('no method handler for method ${call.method}');
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

  Future<String?> switchEffectAndroid(String? effect) {
    return _channel.invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<String?> switchCameraIos(String? effect, int view) {
    return _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<String?> switchFaceMaskAndroid(String? mask) {
    return _channel.invokeMethod<String>('switch_face_mask', {
      PlatformStrings.effect: mask,
    });
  }

  Future<String?> switchFaceMaskIos(String? mask, int view) {
    return _avCameraChannel(view).invokeMethod<String>('switch_face_mask', {
      PlatformStrings.effect: mask,
    });
  }

  Future<String?> switchFilterAndroid(String? mask) {
    return _channel.invokeMethod<String>('switch_filter', {
      PlatformStrings.effect: mask,
    });
  }

  Future<String?> switchFilterIos(String? mask, int view) {
    return _avCameraChannel(view).invokeMethod<String>('switch_filter', {
      PlatformStrings.effect: mask,
    });
  }

  Future<void> startRecordingVideoAndroid() async {
    await _channel.invokeMethod(PlatformStrings.startRecordingVideo);
  }

  Future<String?> stopRecordingVideoAndroid() async {
    await _channel.invokeMethod(PlatformStrings.stopRecordingVideo);
    final Completer completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoCompleted) {
        completer.complete(_videoFilePath);
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoError) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
  }

  Future<void> startRecordingVideoIos(int view) async {
    await _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.startRecordingVideo);
  }

  Future<String?> stopRecordingVideoIos(int view) async {
    await _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.stopRecordingVideo);
    final Completer completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoCompleted) {
        completer.complete(_videoFilePath);
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoError) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
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

  Future<String?> takeScreenShot() async {
    await _channel.invokeMethod("take_screenshot");
    final Completer<String> completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      } else if (_screenshotResponse == ScreenshotResponse.screenshotTaken) {
        completer.complete(_screenshotFilePath);
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
  }

  Future<String?> takeScreenShotIos(int view) async {
    await _avCameraChannel(view).invokeMethod<String>("take_screenshot");
    final Completer<String> completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      } else if (_screenshotResponse == ScreenshotResponse.screenshotTaken) {
        completer.complete(_screenshotFilePath);
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
  }

  Future<bool> toggleFlash() async {
    return await _cameraXChannel.invokeMethod<bool>("toggle_flash") ?? false;
  }

  Future<bool> toggleFlashIos(int view) async {
    return await _avCameraChannel(view).invokeMethod<bool>("toggle_flash") ??
        false;
  }

  Future<void> destroy() {
    return _channel.invokeMethod<bool>("destroy");
  }

  Future<void> destroyIos(int view) {
    return _avCameraChannel(view).invokeMethod<bool>("destroy");
  }

  Future<void> switchEffectWithSlot(
      {required String slot, required String path, String targetGameObject = '', int face = 0}) {
    return _channel.invokeMethod("switchEffectWithSlot", {
      "slot": slot,
      "path": path,
      "face": face,
      "targetGameObject": targetGameObject,
    });
  }

  Future<void> switchEffectWithSlotIos(int view,
      {required String slot, required String path, String targetGameObject = '', int face = 0}) {
    return _avCameraChannel(view).invokeMethod("switchEffectWithSlot", {
      "slot": slot,
      "path": path,
      "face": face,
      "targetGameObject": targetGameObject,
    });
  }
}
