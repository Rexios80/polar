// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: document_ignores, unnecessary_cast, require_trailing_commas, rexios_lints/not_null_assertion

part of 'polar_sensor_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarSensorSetting _$PolarSensorSettingFromJson(Map<String, dynamic> json) =>
    PolarSensorSetting._(
      settings: PolarSensorSetting._settingsFromJson(
        json['settings'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PolarSensorSettingToJson(PolarSensorSetting instance) =>
    <String, dynamic>{
      'settings': PolarSensorSetting._settingsToJson(instance.settings),
    };
