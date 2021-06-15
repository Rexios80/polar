part of '../polar.dart';

class PolarSensorSetting {
  final Map<SettingType, int> settings;

  PolarSensorSetting(this.settings);

  // TODO: This probably breaks the platform code
  // They are expecting ints, but jsonEncode only supports Map<String, dynamic>
  Map<String, dynamic> toJson() => Map.fromIterable(settings.entries,
      key: (e) => e.key.toString(), value: (e) => e.value);
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
