enum Resolution { low, medium, high, veryHigh }

extension StringOperators on Resolution {
  String get stringValue {
    return <Resolution, String>{
      Resolution.low: "low",
      Resolution.medium: "medium",
      Resolution.high: "high",
      Resolution.veryHigh: "veryHigh"
    }[this]!;
  }
}

String enumToString(Resolution o) => o.toString().split('.').last;

Resolution enumFromString<T>(String key) => Resolution.values
    .firstWhere((v) => key == enumToString(v), orElse: () => Resolution.low);
