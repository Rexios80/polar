import 'dart:io';

/// OHR data source enum
enum OhrDataType {
  /// 3 ppg + 1 ambient
  // ignore: constant_identifier_names
  ppg3_ambient1,

  /// An unknown [OhrDataType]
  unknown,
}

/// Extensiopn on [OhrDataType]
extension OhrDataTypeExtension on OhrDataType {
  /// Create an [OhrDataType] from json
  static OhrDataType fromJson(dynamic json) {
    if (Platform.isIOS) {
      return OhrDataType.values[json as int];
    } else {
      // This is android
      return OhrDataType.values.byName((json as String).toLowerCase());
    }
  }
}
