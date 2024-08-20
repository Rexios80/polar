// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_ppi_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarPpiData _$PolarPpiDataFromJson(Map<String, dynamic> json) => PolarPpiData(
      (json['timeStamp'] as num).toInt(),
      (json['samples'] as List<dynamic>)
          .map((e) => PpiSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolarPpiDataToJson(PolarPpiData instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp,
      'samples': instance.samples,
    };

PpiSample _$PpiSampleFromJson(Map<String, dynamic> json) => PpiSample(
      (json['hr'] as num).toInt(),
      (json['ppInMs'] as num).toInt(),
      (json['ppErrorEstimate'] as num).toInt(),
      (json['blockerBit'] as num).toInt(),
      (json['skinContactStatus'] as num).toInt(),
      (json['skinContactSupported'] as num).toInt(),
    );

Map<String, dynamic> _$PpiSampleToJson(PpiSample instance) => <String, dynamic>{
      'hr': instance.hr,
      'ppInMs': instance.ppInMs,
      'ppErrorEstimate': instance.ppErrorEstimate,
      'blockerBit': instance.blockerBit,
      'skinContactStatus': instance.skinContactStatus,
      'skinContactSupported': instance.skinContactSupported,
    };
