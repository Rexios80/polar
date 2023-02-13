import 'dart:io';

import 'package:recase/recase.dart';

/// Data types available in Polar devices for online streaming or offline
/// recording.
enum PolarDeviceDataType {
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

  /// Create a [PolarDeviceDataType] from json
  static PolarDeviceDataType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return PolarDeviceDataType.values[json as int];
    } else {
      // This is android
      return PolarDeviceDataType.values.byName((json as String).camelCase);
    }
  }

  /// Convert a [PolarDeviceDataType] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return PolarDeviceDataType.values.indexOf(this);
    } else {
      // This is Android
      return name.snakeCase.toUpperCase();
    }
  }
}
