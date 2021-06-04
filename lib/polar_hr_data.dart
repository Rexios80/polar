part of 'polar.dart';

class PolarHrData {
  late final int hr;
  late final List<int> rrs;
  late final List<int> rrsMs;
  late final bool contactStatus;
  late final bool contactStatusSupported;
  late final bool rrAvailable;

  PolarHrData(
    this.hr,
    this.rrs,
    this.rrsMs,
    this.contactStatus,
    this.contactStatusSupported,
    this.rrAvailable,
  );

  PolarHrData.fromJson(Map<String, dynamic> json) {
    hr = json['hr'];
    rrs = json['rrs'];
    rrsMs = json['rrsMs'];
    contactStatus = json['contactStatus'];
    contactStatusSupported = json['contactStatusSupported'];
    rrAvailable = json['rrAvailable'];
  }
}
