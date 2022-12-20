import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/converters.dart';

part 'polar_sensor_setting.g.dart';

/// polar sensor settings class
@JsonSerializable()
class PolarSensorSetting {
  /// current settings available / set
  @PolarSettingTypeConverter()
  final Map<PolarSettingType, List<int>> settings;

  /// Constructor
  PolarSensorSetting({
    required this.settings,
  });

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
