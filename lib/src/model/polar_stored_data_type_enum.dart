/// Represents the types of stored data that can be deleted from a Polar device.
/// This corresponds to the iOS StoredDataType enum.
enum PolarStoredDataTypeEnum {
  /// Undefined data type
  undefined,

  /// Activity data
  activity,

  /// Auto sample data
  autoSample,

  /// Daily summary data
  dailySummary,

  /// Nightly recovery data
  nightlyRecovery,

  /// SD logs data
  sdlogs,

  /// Sleep data
  sleep,

  /// Sleep score data
  sleepScore,

  /// Skin contact changes data
  skinContactChanges,

  /// Skin temperature data
  skintemp;

  /// Converts this enum to its index for use with the native API.
  int toInt() => index;

  /// Creates a [PolarStoredDataTypeEnum] from an integer index.
  static PolarStoredDataTypeEnum fromInt(int index) {
    if (index < 0 || index >= PolarStoredDataTypeEnum.values.length) {
      throw Exception('Invalid PolarStoredDataTypeEnum index: $index');
    }
    return PolarStoredDataTypeEnum.values[index];
  }

  /// Converts this enum to a JSON string.
  String toJson() => name;

  /// Creates a [PolarStoredDataTypeEnum] from a JSON string.
  static PolarStoredDataTypeEnum fromJson(String json) {
    return PolarStoredDataTypeEnum.values.firstWhere(
      (e) => e.name == json,
      orElse: () => throw Exception('Unknown PolarStoredDataTypeEnum: $json'),
    );
  }
}
