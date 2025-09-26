import 'package:polar/src/model/polar_activity_samples_data.dart';

/// Represents activity sample data for a specific date from a Polar device.
/// This corresponds to PolarActivitySamplesDayData from the native SDK.
class PolarActivitySampleData {
  /// The date for which the activity sample data is recorded.
  final DateTime? date;

  /// List of activity samples data recorded throughout the day.
  final List<PolarActivitySamplesData> samplesDataList;

  /// Creates a new [PolarActivitySampleData] instance.
  PolarActivitySampleData({
    this.date,
    required this.samplesDataList,
  });

  /// Creates a [PolarActivitySampleData] instance from a JSON map.
  factory PolarActivitySampleData.fromJson(Map<String, dynamic> json) {
    return PolarActivitySampleData(
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      samplesDataList: (json['samplesDataList'] as List<dynamic>?)
              ?.map((e) =>
                  PolarActivitySamplesData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this [PolarActivitySampleData] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (date != null) 'date': date!.toIso8601String(),
      'samplesDataList': samplesDataList.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PolarActivitySampleData(date: $date, samplesDataList: ${samplesDataList.length} items)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolarActivitySampleData &&
        other.date == date &&
        _listEquals(other.samplesDataList, samplesDataList);
  }

  @override
  int get hashCode => Object.hash(date, Object.hashAll(samplesDataList));

  /// Helper method to compare lists
  bool _listEquals(
      List<PolarActivitySamplesData> a, List<PolarActivitySamplesData> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
