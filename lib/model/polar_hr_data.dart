part of '../polar.dart';

class PolarHrData {
  final int hr;
  final List<int> rrs;
  final List<int> rrsMs;
  final bool contactStatus;
  final bool contactStatusSupported;

  PolarHrData.fromJson(Map<String, dynamic> json)
      : hr = json['hr'],
        rrs = (json['rrs'] as List).map((e) => e as int).toList(),
        rrsMs = (json['rrsMs'] as List).map((e) => e as int).toList(),
        contactStatus = json['contactStatus'] ?? json['contact'],
        contactStatusSupported =
            json['contactStatusSupported'] ?? json['contactSupported'];
}
