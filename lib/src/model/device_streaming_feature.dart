import 'dart:io';

import 'package:enum_to_string/enum_to_string.dart';
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
  error,
}

/// Extension on [DeviceStreamingFeature]
extension DeviceStreamingFeatureExtension on DeviceStreamingFeature {
  /// Create a [DeviceStreamingFeature] from json
  static DeviceStreamingFeature fromJson(dynamic json) {
    if (Platform.isIOS) {
      return DeviceStreamingFeature.values[json as int];
    } else {
      // This is android
      return EnumToString.fromString(
            DeviceStreamingFeature.values,
            ReCase(json as String).camelCase,
          ) ??
          DeviceStreamingFeature.error;
    }
  }

  /// Convert a [DeviceStreamingFeature] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return DeviceStreamingFeature.values.indexOf(this);
    } else {
      // This is Android
      return ReCase(EnumToString.convertToString(this)).snakeCase.toUpperCase();
    }
  }
}
