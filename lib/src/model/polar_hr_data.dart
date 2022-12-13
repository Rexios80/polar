import 'package:json_annotation/json_annotation.dart';

part 'polar_hr_data.g.dart';

/// Polar hr data
@JsonSerializable(createToJson: false)
class PolarHrData {
  static String _readContactStatus(Map map, String key) =>
      map['contactStatus'] ?? map['contact'];

  static String _readContactStatusSupported(Map map, String key) =>
      map['contactStatusSupported'] ?? map['contactSupported'];

  /// hr in BPM
  final int hr;

  /// rrs RR interval in 1/1024.
  /// R is a the top highest peak in the QRS complex of the ECG wave and RR is the interval between successive Rs.
  final List<int> rrs;

  /// rrs RR interval in ms.
  final List<int> rrsMs;

  /// contact status between the device and the users skin
  @JsonKey(readValue: _readContactStatus)
  final bool contactStatus;

  /// contactSupported if contact is supported
  @JsonKey(readValue: _readContactStatusSupported)
  final bool contactStatusSupported;

  /// Constructor
  PolarHrData({
    required this.hr,
    required this.rrs,
    required this.rrsMs,
    required this.contactStatus,
    required this.contactStatusSupported,
  });

  /// From json
  factory PolarHrData.fromJson(Map<String, dynamic> json) =>
      _$PolarHrDataFromJson(json);
}
