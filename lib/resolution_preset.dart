enum Resolution { low, medium, high, veryHigh }

String enumToString(Resolution o) => o.toString().split('.').last;

Resolution enumFromString<T>(String key) => Resolution.values
    .firstWhere((v) => key == enumToString(v), orElse: () => Resolution.low);

class DeepArResolution {
  DeepArResolution(Resolution preset) {
    getResolutionPreset(preset);
  }

  late int width;
  late int height;

  void getResolutionPreset(Resolution preset) {
    switch (preset) {
      case Resolution.low:
        width = 640;
        height = 360;
        break;
      case Resolution.medium:
        width = 640;
        height = 480;
        break;
      case Resolution.high:
        width = 1280;
        height = 720;
        break;
      case Resolution.veryHigh:
        width = 1920;
        height = 1080;
        break;
      default:
        width = 640;
        height = 480;
    }
  }
}
