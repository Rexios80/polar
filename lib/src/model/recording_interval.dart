///  Recoding intervals for H10 recording start
enum RecordingInterval {
  /// 1 second interval
  interval1s,

  /// 5 second interval
  interval5s;

  /// Create an [RecordingInterval] from json
  static RecordingInterval fromJson(dynamic json) {
    switch (json as int) {
      case 1:
        return RecordingInterval.interval1s;
      case 5:
        return RecordingInterval.interval5s;
      default:
        throw Exception('Unknown RecordingInterval: $json');
    }
  }

  /// Convert a [RecordingInterval] to json
  dynamic toJson() {
    return RecordingInterval.values.indexOf(this);
  }
}
