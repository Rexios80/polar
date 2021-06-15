part of '../polar.dart';

class PolarSensorSetting {
  final Map<SettingType, int> settings;

  PolarSensorSetting(this.settings);

  Map<String, dynamic> toJson() => {
    // TODO
  };
}

enum SettingType {
  /// sample rate in hz
  sampleRate,

  /// resolution in bits
  resolution,

  /// range
  range,

  /// range with min and max allowed values
  rangeMilliunit,

  /// amount of channels available
  channels,

  /// type is unknown
  unknown,
}
