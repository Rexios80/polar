import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/converters.dart';

part 'polar_sensor_setting.g.dart';

/// polar sensor settings class
@JsonSerializable(constructor: '_', converters: [PolarSettingTypeConverter()])
class PolarSensorSetting {
  /// current settings available / set
  final Map<PolarSettingType, List<int>> settings;

  /// Verify that this is a selection of settings and not a list of available settings
  bool get isSelection => settings.values.every((e) => e.length == 1);

  /// Constructor
  PolarSensorSetting._({
    required this.settings,
  });

  /// Constructor with desired settings
  ///
  /// - Parameter settings: single key value pairs to start stream
  PolarSensorSetting(Map<PolarSettingType, int> settings)
      : settings = settings.map((key, value) => MapEntry(key, [value]));

  /// Helper to retrieve max settings available
  ///
  /// - Returns: PolarSensorSetting with max settings
  PolarSensorSetting maxSettings() {
    final selected =
        settings.map((key, value) => MapEntry(key, [value.reduce(max)]));
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
  unknown;
}
