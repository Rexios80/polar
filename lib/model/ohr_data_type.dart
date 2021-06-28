part of '../polar.dart';

/// OHR data source enum
enum OhrDataType {
  /// 3 ppg + 1 ambient
  ppg3_ambient1,

  /// An unknown [OhrDataType]
  unknown,
}

extension OhrDataTypeExtension on OhrDataType {
  /// Create an [OhrDataType] from json
  static OhrDataType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return OhrDataType.values[json as int];
    } else {
      // This is android
      return EnumToString.fromString(
              OhrDataType.values, (json as String).toLowerCase()) ??
          OhrDataType.unknown;
    }
  }
}
