// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas

part of 'polar_sensor_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarSensorSetting _$PolarSensorSettingFromJson(Map<String, dynamic> json) =>
    PolarSensorSetting._(
      settings: (json['settings'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            const PolarSettingTypeConverter().fromJson(k as String),
            (e as List<dynamic>).map((e) => (e as num).toInt()).toList()),
      ),
    );

Map<String, dynamic> _$PolarSensorSettingToJson(PolarSensorSetting instance) =>
    <String, dynamic>{
      'settings': instance.settings.map(
          (k, e) => MapEntry(const PolarSettingTypeConverter().toJson(k), e)),
    };
