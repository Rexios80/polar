// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'led_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedConfig _$LedConfigFromJson(Map<String, dynamic> json) => LedConfig(
      sdkModeLedEnabled: json['sdkModeLedEnabled'] as bool? ?? true,
      ppiModeLedEnabled: json['ppiModeLedEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$LedConfigToJson(LedConfig instance) => <String, dynamic>{
      'sdkModeLedEnabled': instance.sdkModeLedEnabled,
      'ppiModeLedEnabled': instance.ppiModeLedEnabled,
    };
