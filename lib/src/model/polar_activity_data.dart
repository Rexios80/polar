import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'polar_activity_data.g.dart';

/// Converter for ISO 8601 date strings (YYYY-MM-DD)
class Iso8601DateConverter extends JsonConverter<DateTime, String> {
  /// Constructor
  const Iso8601DateConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) =>
      '${object.year.toString().padLeft(4, '0')}-${object.month.toString().padLeft(2, '0')}-${object.day.toString().padLeft(2, '0')}';
}

/// Individual 24/7 HR sample group (from SDK)
/// Contains a time and potentially multiple HR readings
@JsonSerializable()
@immutable
class Polar247HrSamples {
  /// Start time as a string (HH:mm:ss.SSS format)
  final String startTime;

  /// Array of heart rate samples in BPM
  final List<int> hrSamples;

  /// Trigger type that caused this sample to be recorded
  final String triggerType;

  /// Constructor
  const Polar247HrSamples({
    required this.startTime,
    required this.hrSamples,
    required this.triggerType,
  });

  /// From json
  factory Polar247HrSamples.fromJson(Map<String, dynamic> json) =>
      _$Polar247HrSamplesFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$Polar247HrSamplesToJson(this);

  @override
  String toString() {
    return 'Polar247HrSamples(startTime: $startTime, hrSamples: ${hrSamples.length} samples, triggerType: $triggerType)';
  }
}

/// 24/7 HR samples data for a single day
@JsonSerializable()
@immutable
class Polar247HrSamplesData {
  /// Date of the samples (only date part, no time)
  @Iso8601DateConverter()
  final DateTime date;

  /// List of HR sample groups for this day
  final List<Polar247HrSamples> samples;

  /// Constructor
  const Polar247HrSamplesData({required this.date, required this.samples});

  /// From json
  factory Polar247HrSamplesData.fromJson(Map<String, dynamic> json) =>
      _$Polar247HrSamplesDataFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$Polar247HrSamplesDataToJson(this);

  @override
  String toString() {
    return 'Polar247HrSamplesData(date: $date, samples: ${samples.length} groups)';
  }
}
