part of '../polar.dart';

class PolarPpiSample {
  final int ppi;
  final int errorEstimate;
  final int hr;
  final bool blockerBit;
  final bool skinContactStatus;
  final bool skinContactSupported;

  PolarPpiSample.fromJson(Map<String, dynamic> json)
      : ppi = json['ppi'],
        errorEstimate = json['errorEstimate'],
        hr = json['hr'],
        blockerBit = json['blockerBit'],
        skinContactStatus = json['skinContactStatus'],
        skinContactSupported = json['skinContactSupported'];
}
