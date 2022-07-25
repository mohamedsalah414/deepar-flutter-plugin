import 'dart:io';
import 'dart:ui';

T platformRun<T>(
    {required T Function() androidFunction,
    required T Function() iOSFunction}) {
  if (Platform.isAndroid) {
    return androidFunction.call();
  } else if (Platform.isIOS) {
    return iOSFunction.call();
  } else {
    throw ("This platform is not supported");
  }
}

enum CameraDirection { front, rear }

Size sizeFromEncodedString(String dimensions) {
  final width = double.parse(dimensions.split(" ")[0]);
  final height = double.parse(dimensions.split(" ")[1]);
  return Size(width, height);
}
