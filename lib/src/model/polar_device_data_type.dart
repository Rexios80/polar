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
  ppi(supportsStreamSettings: false),

  /// Gyro
  gyro,

  /// Magnetometer
  magnetometer,

  /// HR
  hr(supportsStreamSettings: false),

  /// Temperature
  temperature,

  /// Pressure
  pressure,

  /// skin temperature
  skinTemperature,

  /// location
  location;

  /// If this feature supports stream settings
  final bool supportsStreamSettings;

  /// Constructor
  const PolarDataType({this.supportsStreamSettings = true});

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
