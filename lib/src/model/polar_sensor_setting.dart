import 'dart:io';

import 'package:recase/recase.dart';

/// polar sensor settings class
class PolarSensorSetting {
  /// current settings available / set
  final Map<PolarSettingType, List<int>> settings;

  /// constructor with desired settings
  ///
  /// - Parameter settings: single key value pairs to start stream
  PolarSensorSetting(this.settings);

  /// Convert a [PolarSensorSetting] to json
  Map<String, dynamic> toJson() {
    if (Platform.isIOS) {
      return {
        'settings': {
          for (var e in settings.entries)
            PolarSettingType.values.indexOf(e.key).toString(): e.value.first
        },
      };
    } else {
      // This is Android
      return {
        'settings': {
          for (var e in settings.entries)
            e.key.name.snakeCase.toUpperCase(): e.value
        },
      };
    }
  }

  /// Create a [PolarSensorSetting] from json
  PolarSensorSetting.fromJson(Map<String, dynamic> json)
      : settings = {
          for (var e in (json['settings'] as Map<String, dynamic>).entries)
            PolarSettingType.fromJson(e.key):
                (e.value as List).cast<int>().toList()
        };
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

  /// Convert a [PolarSettingType] to json
  static PolarSettingType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return PolarSettingType.values[int.parse(json as String)];
    } else {
      // This is android
      return PolarSettingType.values.byName((json as String).camelCase);
    }
  }
}
