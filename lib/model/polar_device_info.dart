part of '../polar.dart';

class PolarDeviceInfo {
  final String deviceId;
  final String address;
  final int rssi;
  final String name;
  final bool isConnectable;

  PolarDeviceInfo.fromJson(Map<String, dynamic> json)
      : deviceId = json['deviceId'],
        address = json['address'],
        rssi = json['rssi'],
        name = json['name'],
        isConnectable = json['isConnectable'] ?? json['connectable'];
}
