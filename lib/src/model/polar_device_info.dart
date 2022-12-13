import 'package:json_annotation/json_annotation.dart';

part 'polar_device_info.g.dart';

/// Polar device info
@JsonSerializable(createToJson: false)
class PolarDeviceInfo {
  static dynamic _readConnectable(Map json, String key) =>
      json['isConnectable'] ?? json['connectable'];

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
  @JsonKey(readValue: _readConnectable)
  final bool isConnectable;

  /// Constructor
  PolarDeviceInfo({
    required this.deviceId,
    required this.address,
    required this.rssi,
    required this.name,
    required this.isConnectable,
  });

  /// From json
  factory PolarDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$PolarDeviceInfoFromJson(json);
}
