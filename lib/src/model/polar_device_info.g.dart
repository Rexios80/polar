// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

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
