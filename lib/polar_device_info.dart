part of 'polar.dart';

class PolarDeviceInfo {
  late final String deviceId;
  late final String address;
  late final int rssi;
  late final String name;
  late final bool isConnectable;

  PolarDeviceInfo(
    this.deviceId,
    this.address,
    this.rssi,
    this.name,
    this.isConnectable,
  );

  PolarDeviceInfo.fromJson(Map<String, dynamic> json) {
    deviceId = json['deviceId'];
    address = json['address'];
    rssi = json['rssi'];
    name = json['name'];
    isConnectable = json['isConnectable'] ?? json['connectable'];
  }
}
