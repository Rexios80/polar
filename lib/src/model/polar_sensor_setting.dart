import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:polar/src/model/convert.dart';

part 'polar_sensor_setting.g.dart';

/// polar sensor settings class
@JsonSerializable(constructor: '_')
@immutable
class PolarSensorSetting {
  static const _settingTypeConverter = PolarSettingTypeConverter();

  static Map<PolarSettingType, List<int>> _settingsFromJson(
    Map<String, dynamic> json,
  ) {
    return json.map(
      (key, value) => MapEntry(
        _settingTypeConverter.fromJson(key),
        (value as List).cast<int>(),
      ),
    );
  }

  static Map<String, dynamic> _settingsToJson(
    Map<PolarSettingType, List<int>> settings,
  ) {
    return settings.map(
      (key, value) => MapEntry(_settingTypeConverter.toJson(key), value),
    );
  }

  /// current settings available / set
  @JsonKey(fromJson: _settingsFromJson, toJson: _settingsToJson)
  final Map<PolarSettingType, List<int>> settings;

  /// Verify that this is a selection of settings and not a list of available settings
  bool get isSelection => settings.values.every((e) => e.length == 1);

  /// Constructor
  const PolarSensorSetting._({required this.settings});

  /// Constructor with desired settings
  ///
  /// - Parameter settings: single key value pairs to start stream
  PolarSensorSetting(Map<PolarSettingType, int> settings)
    : settings = settings.map((key, value) => MapEntry(key, [value]));

  /// Helper to retrieve max settings available
  ///
  /// - Returns: PolarSensorSetting with max settings
  PolarSensorSetting maxSettings() {
    final selected = settings.map(
      (key, value) => MapEntry(key, [value.reduce(max)]),
    );
    return PolarSensorSetting._(settings: selected);
  }

  /// From json
  factory PolarSensorSetting.fromJson(Map<String, dynamic> json) =>
      _$PolarSensorSettingFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarSensorSettingToJson(this);
}

/// settings type
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
