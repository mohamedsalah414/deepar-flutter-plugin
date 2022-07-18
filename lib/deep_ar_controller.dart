import 'dart:io';
import 'package:deep_ar/deep_ar_platform_handler.dart';
import 'package:deep_ar/platform_strings.dart';
import 'package:deep_ar/resolution_preset.dart';
import 'package:deep_ar/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';

enum DeepArNativeResponse { videoStarted, videoCompleted, videoError }

class DeepArController {
  late final DeepArPlatformHandler _deepArPlatformHandler;
  late final Resolution _resolution;

  int? _textureId;
  Size? _imageSize;
  double? _aspectRatio;
  bool _hasPermission = false;
  String? _iosLicenseKey;
  bool _isRecording = false;

  CameraDirection _cameraDirection = CameraDirection.front;
  bool _flashState = false;

  DeepArController() {
    _deepArPlatformHandler = DeepArPlatformHandler();
  }

  void setNativeResponseListener() {
    try {
      _deepArPlatformHandler.setListener(_textureId!);
    } catch (e) {
      print(e);
    }
  }

  ///Return true if the camera preview is intialized
  ///
  ///For [iOS], please call the function after [DeepArPreview] widget has been built.
  bool get isInitialized => _textureId != null;

  ///If the user has allowed required camera permissions
  bool get hasPermisssion => _hasPermission;

  ///Aspect ratio of the preivew image
  ///
  ///For [iOS], please call the function after [DeepArPreview] widget has been built.
  double get aspectRatio => _aspectRatio ?? 1.0;

  ///Return true if the recording is in progress.
  bool get isRecording => _isRecording;

  ///Size of the preview image
  ///
  ///For [iOS], please call the function after [DeepArPreview] widget has been built.
  Size get imageDimensions {
    assert(isInitialized, "DeepArController isn't initialized yet");
    return _imageSize!;
  }

  ///Get current  camera direction as [CameraDirection.front] or [CameraDirection.rear]
  CameraDirection get cameraDirection => _cameraDirection;

  ///Get current flash state as [FlashState.on] or [FlashState.off]
  bool get flashState => _flashState;

  ///Initializes the DeepAR SDK with license keys and asks for required camera and microphone permissions.
  ///Returns false if fails to initalize;
  ///
  ///[androidLicenseKey] and [iosLicenseKey] both cannot be null together.
  ///
  ///Recommended resolution: [Resolution.high] for optimum quality without performance tradeoffs
  Future<bool> initialize({
    required String? androidLicenseKey,
    required String? iosLicenseKey,
    Resolution resolution = Resolution.high,
  }) async {
    assert(androidLicenseKey != null || iosLicenseKey != null,
        "Both android and iOS license keys cannot be null");

    _iosLicenseKey = iosLicenseKey;
    _resolution = resolution;
    _hasPermission = await _askMediaPermission();

    if (!_hasPermission) return false;

    if (Platform.isAndroid) {
      assert(androidLicenseKey != null, "androidLicenseKey missing");
      String? dimensions = await _deepArPlatformHandler.initialize(
          androidLicenseKey!, resolution);
      if (dimensions != null) {
        _imageSize = sizeFromEncodedString(dimensions);
        _aspectRatio = _imageSize!.width / _imageSize!.height;
        _textureId = await _deepArPlatformHandler.startCameraAndroid();
        return true;
      }
    } else if (Platform.isIOS) {
      assert(iosLicenseKey != null, "iosLicenseKey missing");
      _imageSize = iOSImageSizeFromResolution(resolution);
      _aspectRatio = _imageSize!.width / _imageSize!.height;
      _textureId = -1;
      return true;
    } else {
      throw ("Platform not supported");
    }
    return false;
  }

  ///Builds and returns the DeepAR Camera Widget.
  ///
  ///[oniOSViewCreated] callback to update [imageDimensions] and [aspectRatio] after iOS
  ///widget is built
  ///
  ///Not recommneded to use directly. Please use the wrapper [DeepArPreview] instead.
  ///
  ///Android layer uses FlutterTexture while iOS uses NativeViews.
  ///See: https://api.flutter.dev/flutter/widgets/Texture-class.html
  ///https://docs.flutter.dev/development/platform-integration/ios/platform-views
  Widget buildPreview({Function? oniOSViewCreated}) {
    if (Platform.isAndroid) {
      return Texture(textureId: _textureId!);
    } else if (Platform.isIOS) {
      return UiKitView(
          viewType: "deep_ar_view",
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            PlatformStrings.licenseKey: _iosLicenseKey,
            PlatformStrings.resolution: _resolution.stringValue
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: ((id) {
            _textureId = id;
            _deepArPlatformHandler
                .getResolutionDimensions(_textureId!)
                .then((value) {
              if (value != null) {
                _imageSize = sizeFromEncodedString(value);
                _aspectRatio = _imageSize!.width / _imageSize!.height;
              }
              oniOSViewCreated?.call();
            });
          }));
    } else {
      throw ("Platform not supported.");
    }
  }

  ///Switch DeepAR with the passed [effect] path fromfresol assets
  Future<String?> switchEffect(String? effect) {
    return platformRun(
        androidFunction: () =>
            _deepArPlatformHandler.switchEffectAndroid(effect),
        iOSFunction: () =>
            _deepArPlatformHandler.switchCameraIos(effect, _textureId!));
  }

  ///Switch DeepAR with the passed [mask] path fromfresol assets
  Future<String?> switchFaceMask(String? mask) {
    return platformRun(
        androidFunction: () =>
            _deepArPlatformHandler.switchFaceMaskAndroid(mask),
        iOSFunction: () =>
            _deepArPlatformHandler.switchFaceMaskIos(mask, _textureId!));
  }

///Switch DeepAR with the passed [filter] path fromfresol assets
  Future<String?> switchFilter(String? filter) {
    return platformRun(
        androidFunction: () =>
            _deepArPlatformHandler.switchFilterAndroid(filter),
        iOSFunction: () =>
            _deepArPlatformHandler.switchFilterIos(filter, _textureId!));
  }

  Future<void> startVideoRecording() async {
    if (_isRecording) throw ("Recording already in progress");
    if (Platform.isAndroid) {
      _deepArPlatformHandler.startRecordingVideoAndroid();
      _isRecording = true;
    } else {
      _deepArPlatformHandler.startRecordingVideoIos(_textureId!);
      _isRecording = true;
    }
  }

  Future<File?> stopVideoRecording() async {
    if (!_isRecording)
      throw ("Invalid stopVideoRecording trigger. No recording was in progress");
    final _file = await platformRun(
        androidFunction: _deepArPlatformHandler.stopRecordingVideoAndroid,
        iOSFunction: () =>
            _deepArPlatformHandler.stopRecordingVideoIos(_textureId!));
    _isRecording = false;
    print("file_path_ ${_file?.path}");
    return _file;
  }

  ///Flips Camera and return the current direction
  Future<CameraDirection> flipCamera() async {
    final result = await platformRun(
        androidFunction: _deepArPlatformHandler.flipCamera,
        iOSFunction: () => _deepArPlatformHandler.flipCameraIos(_textureId!));
    if (result != null && result) {
      _cameraDirection = _cameraDirection == CameraDirection.front
          ? CameraDirection.rear
          : CameraDirection.front;
      if (_cameraDirection == CameraDirection.front) _flashState = false;
    }
    return _cameraDirection;
  }

  ///Takes picture of the current frame and returns a [File]
  Future<File?> takeScreenshot() {
    return platformRun(
        androidFunction: _deepArPlatformHandler.takeScreenShot,
        iOSFunction: () =>
            _deepArPlatformHandler.takeScreenShotIos(_textureId!));
  }

  ///Returns true if toggle was success
  Future<bool> toggleFlash() async {
    bool result = await platformRun(
        androidFunction: _deepArPlatformHandler.toggleFlash,
        iOSFunction: () => _deepArPlatformHandler.toggleFlashIos(_textureId!));
    _flashState = result;
    return _flashState;
  }

  Size toSize(Map<dynamic, dynamic> data) {
    final width = data['width'];
    final height = data['height'];
    return Size(width, height);
  }

  Future<bool> _askMediaPermission() async {
    await [
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
