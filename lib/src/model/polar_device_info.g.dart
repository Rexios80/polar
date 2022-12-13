// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'polar_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarDeviceInfo _$PolarDeviceInfoFromJson(Map<String, dynamic> json) =>
    PolarDeviceInfo(
      deviceId: json['deviceId'] as String,
      address: json['address'] as String,
      rssi: json['rssi'] as int,
      name: json['name'] as String,
      isConnectable:
          PolarDeviceInfo._readConnectable(json, 'isConnectable') as bool,
    );
