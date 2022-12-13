// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_cast, require_trailing_commas

part of 'polar_hr_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarHrData _$PolarHrDataFromJson(Map<String, dynamic> json) => PolarHrData(
      hr: json['hr'] as int,
      rrs: (json['rrs'] as List<dynamic>).map((e) => e as int).toList(),
      rrsMs: (json['rrsMs'] as List<dynamic>).map((e) => e as int).toList(),
      contactStatus:
          PolarHrData._readContactStatus(json, 'contactStatus') as bool,
      contactStatusSupported: PolarHrData._readContactStatusSupported(
          json, 'contactStatusSupported') as bool,
    );
