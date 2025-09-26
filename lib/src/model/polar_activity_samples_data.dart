import 'package:polar/src/model/polar_activity_info.dart';

/// Represents activity samples data for a specific time period from a Polar device.
/// This corresponds to PolarActivitySamplesData from the native SDK.
class PolarActivitySamplesData {
  /// The start time for this sample data.
  final DateTime startTime;

  /// MET (Metabolic Equivalent of Task) recording interval in seconds.
  final int? metRecordingInterval;

  /// List of MET sample values.
  final List<double>? metSamples;

  /// Step recording interval in seconds.
  final int? stepRecordingInterval;

  /// List of step sample values.
  final List<int>? stepSamples;

  /// List of activity information for this time period.
  final List<PolarActivityInfo> activityInfoList;

  /// Creates a new [PolarActivitySamplesData] instance.
  PolarActivitySamplesData({
    required this.startTime,
    this.metRecordingInterval,
    this.metSamples,
    this.stepRecordingInterval,
    this.stepSamples,
    required this.activityInfoList,
  });

  /// Creates a [PolarActivitySamplesData] instance from a JSON map.
  factory PolarActivitySamplesData.fromJson(Map<String, dynamic> json) {
    return PolarActivitySamplesData(
      startTime: DateTime.parse(json['startTime']),
      metRecordingInterval: json['metRecordingInterval'] as int?,
      metSamples: (json['metSamples'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      stepRecordingInterval: json['stepRecordingInterval'] as int?,
      stepSamples: (json['stepSamples'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      activityInfoList: (json['activityInfoList'] as List<dynamic>?)
              ?.map(
                  (e) => PolarActivityInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this [PolarActivitySamplesData] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      if (metRecordingInterval != null)
        'metRecordingInterval': metRecordingInterval,
      if (metSamples != null) 'metSamples': metSamples,
      if (stepRecordingInterval != null)
        'stepRecordingInterval': stepRecordingInterval,
      if (stepSamples != null) 'stepSamples': stepSamples,
      'activityInfoList': activityInfoList.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PolarActivitySamplesData(startTime: $startTime, metSamples: ${metSamples?.length ?? 0}, stepSamples: ${stepSamples?.length ?? 0}, activityInfo: ${activityInfoList.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolarActivitySamplesData &&
        other.startTime == startTime &&
        other.metRecordingInterval == metRecordingInterval &&
        _listEquals(other.metSamples, metSamples) &&
        other.stepRecordingInterval == stepRecordingInterval &&
        _listEquals(other.stepSamples, stepSamples) &&
        _listEquals(other.activityInfoList, activityInfoList);
  }

  @override
  int get hashCode => Object.hash(
        startTime,
        metRecordingInterval,
        Object.hashAll(metSamples ?? []),
        stepRecordingInterval,
        Object.hashAll(stepSamples ?? []),
        Object.hashAll(activityInfoList),
      );

  /// Helper method to compare nullable lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
