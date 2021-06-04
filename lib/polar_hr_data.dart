part of 'polar.dart';

class PolarHrData {
  late final int hr;
  late final List<int> rrs;
  late final List<int> rrsMs;
  late final bool contactStatus;
  late final bool contactStatusSupported;

  PolarHrData(
    this.hr,
    this.rrs,
    this.rrsMs,
    this.contactStatus,
    this.contactStatusSupported,
  );

  PolarHrData.fromJson(Map<String, dynamic> json) {
    hr = json['hr'];
    rrs = (json['rrs'] as List).map((e) => e as int).toList();
    rrsMs = (json['rrsMs'] as List).map((e) => e as int).toList();
    contactStatus = json['contactStatus'] ?? json['contact'];
    contactStatusSupported = json['contactStatusSupported'] ?? json['contactSupported'];
  }
}
