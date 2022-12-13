import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:polar/polar.dart';
import 'package:recase/recase.dart';

/// Converts platform values to booleans
/// - The iOS SDK uses `0` and `1` for booleans
/// - The Android SDK uses `true` and `false` for booleans
class PlatformBooleanConverter extends JsonConverter<bool, dynamic> {
  /// Constructor
  const PlatformBooleanConverter();

  @override
  bool fromJson(dynamic json) {
    if (Platform.isIOS) {
      return json != 0;
    } else {
      return json;
    }
  }

  @override
  dynamic toJson(bool object) {
    if (Platform.isIOS) {
      return object ? 1 : 0;
    } else {
      return object;
    }
  }
}

/// Converter for [OhrDataType]
class OhrDataTypeConverter extends JsonConverter<OhrDataType, dynamic> {
  /// Constructor
  const OhrDataTypeConverter();

  @override
  OhrDataType fromJson(dynamic json) {
    if (Platform.isIOS) {
      switch (json as int) {
        case 4:
          return OhrDataType.ppg3_ambient1;
        default: // 18
          return OhrDataType.unknown;
      }
    } else {
      // This is android
      return OhrDataType.values.byName((json as String).toLowerCase());
    }
  }

  @override
  toJson(OhrDataType object) => throw UnimplementedError();
}

/// Converter for unix time
class UnixTimeConverter extends JsonConverter<DateTime, int> {
  /// Constructor
  const UnixTimeConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

/// Converter for [PolarSettingType]
class PolarSettingTypeConverter
    extends JsonConverter<PolarSettingType, String> {
  /// Constructor
  const PolarSettingTypeConverter();

  @override
  PolarSettingType fromJson(String json) {
    if (Platform.isIOS) {
      return PolarSettingType.values[int.parse(json)];
    } else {
      // This is android
      return PolarSettingType.values.byName(json.camelCase);
    }
  }

  @override
  String toJson(PolarSettingType object) => throw UnimplementedError();
}
