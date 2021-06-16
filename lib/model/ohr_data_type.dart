part of '../polar.dart';

enum OhrDataType {
  ppg3_ambient1,
  unknown,
}

extension OhrDataTypeExtension on OhrDataType {
  static OhrDataType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return OhrDataType.values[json as int];
    } else {
      // This is android
      return EnumToString.fromString(
              OhrDataType.values, ReCase(json as String).camelCase) ??
          OhrDataType.unknown;
    }
  }
}
