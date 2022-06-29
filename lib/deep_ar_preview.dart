import 'package:camera/camera.dart';
import 'package:deep_ar/deep_ar_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeepArPreview extends StatelessWidget {
  final DeepArController deepArController;
  final Widget? child;
  const DeepArPreview(this.deepArController, {this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return deepArController.value.isInitialized
        ? ValueListenableBuilder<CameraValue>(
            valueListenable: deepArController,
            builder: (BuildContext context, Object? value, Widget? child) {
              return AspectRatio(
                aspectRatio: _isLandscape()
                    ? deepArController.value.aspectRatio
                    : (1 / deepArController.value.aspectRatio),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _wrapInRotatedBox(child: deepArController.buildPreview()),
                    child ?? Container(),
                  ],
                ),
              );
            },
            child: child,
          )
        : Container();
  }

  Widget _wrapInRotatedBox({required Widget child}) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return child;
    }

    return RotatedBox(
      quarterTurns: _getQuarterTurns(),
      child: child,
    );
  }

  bool _isLandscape() {
    return <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ].contains(_getApplicableOrientation());
  }

  int _getQuarterTurns() {
    final Map<DeviceOrientation, int> turns = <DeviceOrientation, int>{
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeRight: 1,
      DeviceOrientation.portraitDown: 2,
      DeviceOrientation.landscapeLeft: 3,
    };
    return turns[_getApplicableOrientation()]!;
  }

  DeviceOrientation _getApplicableOrientation() {
    return deepArController.value.isRecordingVideo
        ? deepArController.value.recordingOrientation!
        : (deepArController.value.previewPauseOrientation ??
            deepArController.value.lockedCaptureOrientation ??
            deepArController.value.deviceOrientation);
  }
}
