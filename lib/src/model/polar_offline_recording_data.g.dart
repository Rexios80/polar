// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_offline_recording_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarOfflineRecordingData _$PolarOfflineRecordingDataFromJson(
        Map<String, dynamic> json) =>
    PolarOfflineRecordingData(
      type: PolarOfflineRecordingData._typeFromJson(json['type']),
      startTime: (json['startTime'] as num).toInt(),
      settings: json['settings'] == null
          ? null
          : PolarSensorSetting.fromJson(
              json['settings'] as Map<String, dynamic>),
      accData: json['accData'] == null
          ? null
          : PolarStreamingData<PolarAccSample>.fromJson(
              json['accData'] as Map<String, dynamic>),
      gyroData: json['gyroData'] == null
          ? null
          : PolarStreamingData<PolarGyroSample>.fromJson(
              json['gyroData'] as Map<String, dynamic>),
      magData: json['magData'] == null
          ? null
          : PolarStreamingData<PolarMagnetometerSample>.fromJson(
              json['magData'] as Map<String, dynamic>),
      ppgData: json['ppgData'] == null
          ? null
          : PolarPpgData.fromJson(json['ppgData'] as Map<String, dynamic>),
      ppiData: json['ppiData'] == null
          ? null
          : PolarStreamingData<PolarPpiSample>.fromJson(
              json['ppiData'] as Map<String, dynamic>),
      hrData: json['hrData'] == null
          ? null
          : PolarStreamingData<PolarHrSample>.fromJson(
              json['hrData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PolarOfflineRecordingDataToJson(
        PolarOfflineRecordingData instance) =>
    <String, dynamic>{
      'type': PolarOfflineRecordingData._typeToJson(instance.type),
      'startTime': instance.startTime,
      'settings': instance.settings,
      'accData': instance.accData,
      'gyroData': instance.gyroData,
      'magData': instance.magData,
      'ppgData': instance.ppgData,
      'ppiData': instance.ppiData,
      'hrData': instance.hrData,
    };
