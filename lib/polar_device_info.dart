part of 'polar.dart';

class PolarDeviceInfo {
  late final String deviceId;
  late final String address;
  late final int rssi;
  late final String name;
  late final bool isConnectable;

  PolarDeviceInfo._fromJson(Map<String, dynamic> json) {
    deviceId = json['deviceId'];
    address = json['address'];
    rssi = json['rssi'];
    name = json['name'];
    isConnectable = json['isConnectable'] ?? json['connectable'];
  }
}
