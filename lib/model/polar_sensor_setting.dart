part of '../polar.dart';

class PolarSensorSetting {
  final Map<PolarSettingType, List<int>> settings;

  PolarSensorSetting(this.settings);

  Map<String, dynamic> toJson() {
    if (Platform.isIOS) {
      return {
        'settings': Map<String, int>.fromIterable(settings.entries,
            key: (e) => PolarSettingType.values.indexOf(e.key).toString(),
            value: (e) => e.value.first),
      };
    } else {
      // This is Android
      return {
        'settings': Map.fromIterable(settings.entries,
            key: (e) => e.key.toString().toScreamingSnakeCase(),
            value: (e) => e.value),
      };
    }
  }

  PolarSensorSetting.fromJson(Map<String, dynamic> json)
      : settings = Map<PolarSettingType, List<int>>.fromIterable(
          (json['settings'] as Map<String, dynamic>).entries,
          key: (e) => PolarSettingTypeExtension.fromJson(e.key),
          value: (e) => (e.value as List).map((e) => e as int).toList(),
        );
}

enum PolarSettingType {
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

extension PolarSettingTypeExtension on PolarSettingType {
  static PolarSettingType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return PolarSettingType.values[int.parse(json as String)];
    } else {
      // This is android
      return EnumToString.fromString(
              PolarSettingType.values, ReCase(json as String).camelCase) ??
          PolarSettingType.unknown;
    }
  }
}
