import 'dart:io';

import 'package:recase/recase.dart';

/// Data types available in Polar devices for online streaming or offline
/// recording.
enum PolarDataType {
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

  /// HR
  hr;

  /// Create a [PolarDataType] from json
  static PolarDataType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return PolarDataType.values[json as int];
    } else {
      // This is android
      return PolarDataType.values.byName((json as String).camelCase);
    }
  }

  /// Convert a [PolarDataType] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return PolarDataType.values.indexOf(this);
    } else {
      // This is Android
      return name.snakeCase.toUpperCase();
    }
  }
}
