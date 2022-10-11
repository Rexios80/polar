import 'dart:io';

import 'package:recase/recase.dart';

/// device streaming features
enum DeviceStreamingFeature {
  /// ECG
  ecg,

  /// ACC
  acc,

  /// PPG
  ppg,

  /// PPI
  ppi,

  /// Gyro
  gyro,

  /// Magnetometer
  magnetometer,

  /// Unknown feature
  error;

  /// Create a [DeviceStreamingFeature] from json
  static DeviceStreamingFeature fromJson(dynamic json) {
    if (Platform.isIOS) {
      return DeviceStreamingFeature.values[json as int];
    } else {
      // This is android
      return DeviceStreamingFeature.values
          .byName(ReCase(json as String).camelCase);
    }
  }

  /// Convert a [DeviceStreamingFeature] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return DeviceStreamingFeature.values.indexOf(this);
    } else {
      // This is Android
      return ReCase(name).snakeCase.toUpperCase();
    }
  }
}
