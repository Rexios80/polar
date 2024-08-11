// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarDeviceInfo _$PolarDeviceInfoFromJson(Map<String, dynamic> json) =>
    PolarDeviceInfo(
      deviceId: json['deviceId'] as String,
      address: json['address'] as String,
      rssi: (json['rssi'] as num).toInt(),
      name: json['name'] as String,
      isConnectable: _readConnectable(json, 'isConnectable') as bool,
    );

Map<String, dynamic> _$PolarDeviceInfoToJson(PolarDeviceInfo instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'address': instance.address,
      'rssi': instance.rssi,
      'name': instance.name,
      'isConnectable': instance.isConnectable,
    };
