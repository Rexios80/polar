import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/convert.dart';

part 'polar_device_info.g.dart';

/// Polar device info
@JsonSerializable(createToJson: false)
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

  static Object? _readConnectable(Map json, String key) => readPlatformValue(
        json,
        {
          TargetPlatform.iOS: 'connectable',
          TargetPlatform.android: 'isConnectable',
        },
      );

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
