import 'dart:io';

/// OHR data source enum
enum OhrDataType {
  /// 3 ppg + 1 ambient
  // ignore: constant_identifier_names
  ppg3_ambient1,

  /// An unknown [OhrDataType]
  unknown,
}

/// Extension on [OhrDataType]
extension OhrDataTypeExtension on OhrDataType {
  /// Create an [OhrDataType] from json
  static OhrDataType fromJson(dynamic json) {
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
}
