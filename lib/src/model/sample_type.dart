import 'dart:io';

/// Sample types for H10 recording start
enum SampleType {
  /// recording type to use is hr in BPM
  hr,

  /// recording type to use is rr interval
  rr;

  /// Create a [SampleType] from json
  static SampleType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return SampleType.values[json as int];
    } else {
      // This is android
      return SampleType.values.byName((json as String).toLowerCase());
    }
  }

  /// Convert a [SampleType] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return SampleType.values.indexOf(this);
    } else {
      // This is Android
      return name.toUpperCase();
    }
  }
}
