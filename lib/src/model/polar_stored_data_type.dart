/// Represents the types of data that can be stored on a Polar device.
enum PolarStoredDataType {
  /// Heart rate data
  hr,

  /// ECG data
  ecg,

  /// Accelerometer data
  acc,

  /// PPG data
  ppg,

  /// PPI data
  ppi,

  /// Gyroscope data
  gyro,

  /// Magnetometer data
  magnetometer,

  /// Temperature data
  temperature,

  /// Pressure data
  pressure,

  /// Location data
  location,

  /// Skin temperature data
  skinTemperature;

  /// Converts this enum to a JSON string.
  String toJson() => name;

  /// Creates a [PolarStoredDataType] from a JSON string.
  static PolarStoredDataType fromJson(String json) {
    return PolarStoredDataType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => throw Exception('Unknown PolarStoredDataType: $json'),
    );
  }
}
