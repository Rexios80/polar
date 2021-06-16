part of '../polar.dart';

/// Polar streaming features
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

extension DeviceStreamingFeatureExtension on DeviceStreamingFeature {
  static DeviceStreamingFeature fromJson(dynamic json) {
    if (Platform.isIOS) {
      return DeviceStreamingFeature.values[json as int];
    } else {
      // This is android
      return EnumToString.fromString(
              DeviceStreamingFeature.values, (json as String).toLowerCase()) ??
          DeviceStreamingFeature.error;
    }
  }
}
