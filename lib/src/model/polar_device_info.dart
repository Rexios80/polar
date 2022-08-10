/// Polar device info
class PolarDeviceInfo {
  /// polar device id or UUID for 3rd party sensors
  final String deviceId;

  /// The mac address of the polar device.
  /// Definitely empty on iOS.
  /// Probably empty on modern Android versions.
  final String address;

  /// RSSI (Received Signal Strength Indicator) value from advertisement
  final int rssi;

  /// local name from advertisement
  final String name;

  /// true adv type is connectable
  final bool isConnectable;

  /// Create a [PolarDeviceInfo] from json
  PolarDeviceInfo.fromJson(Map<String, dynamic> json)
      : deviceId = json['deviceId'],
        address = json['address'],
        rssi = json['rssi'],
        name = json['name'],
        isConnectable = json['isConnectable'] ?? json['connectable'];
}
