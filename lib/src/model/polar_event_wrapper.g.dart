// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_event_wrapper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarEventWrapper _$PolarEventWrapperFromJson(Map<String, dynamic> json) =>
    PolarEventWrapper(
      $enumDecode(_$PolarEventEnumMap, json['event']),
      json['data'],
    );

Map<String, dynamic> _$PolarEventWrapperToJson(PolarEventWrapper instance) =>
    <String, dynamic>{
      'event': _$PolarEventEnumMap[instance.event]!,
      'data': instance.data,
    };

const _$PolarEventEnumMap = {
  PolarEvent.blePowerStateChanged: 'blePowerStateChanged',
  PolarEvent.sdkFeatureReady: 'sdkFeatureReady',
  PolarEvent.deviceConnected: 'deviceConnected',
  PolarEvent.deviceConnecting: 'deviceConnecting',
  PolarEvent.deviceDisconnected: 'deviceDisconnected',
  PolarEvent.disInformationReceived: 'disInformationReceived',
  PolarEvent.batteryLevelReceived: 'batteryLevelReceived',
};
