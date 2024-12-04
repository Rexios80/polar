import 'dart:io';

import 'package:polar/polar.dart';
import 'package:polar/src/model/convert.dart';

/// An abstract class representing offline recording data from a Polar device.
abstract class PolarOfflineRecordingData {
  /// The start time of the recording.
  final DateTime startTime;

  /// The sensor settings associated with the recording.
  final PolarSensorSetting settings;

  /// Constructor for [PolarOfflineRecordingData].
  PolarOfflineRecordingData({
    required this.startTime,
    required this.settings,
  });
}

/// A class representing accelerometer offline recording data from a Polar device,
/// extending the generic [PolarOfflineRecordingData].
class AccOfflineRecording extends PolarOfflineRecordingData {
  /// The accelerometer data.
  final PolarAccData data;

  /// Constructor for [AccOfflineRecording].
  AccOfflineRecording({
    required this.data,
    required super.startTime,
    required super.settings,
  });

  /// Factory method to create an instance from JSON.
  factory AccOfflineRecording.fromJson(Map<String, dynamic> json) {
    return AccOfflineRecording(
      data: PolarAccData.fromJson(json['data']),
      startTime: Platform.isIOS
          ? const PolarSampleTimestampConverter().fromJson(json['startTime'])
          : const MapToDateTimeConverter().fromJson(
              json['startTime'],
            ),
      settings: PolarSensorSetting.fromJson(json['settings']),
    );
  }
}

/// A class representing PPI (Peak-to-Peak Interval) offline recording data from a Polar device,
/// extending the generic [PolarOfflineRecordingData].
class PpiOfflineRecording extends PolarOfflineRecordingData {
  /// The PPI data.
  final PolarPpiData data;

  /// Constructor for [PpiOfflineRecording].
  PpiOfflineRecording({
    required this.data,
    required super.startTime,
    required super.settings,
  });

  /// Factory method to create an instance from JSON.
  factory PpiOfflineRecording.fromJson(Map<String, dynamic> json) {
    return PpiOfflineRecording(
      data: PolarPpiData.fromJson(json['data']),
      startTime: Platform.isIOS
          ? const PolarSampleTimestampConverter().fromJson(json['startTime'])
          : const MapToDateTimeConverter().fromJson(
              json['startTime'],
            ),
      settings: PolarSensorSetting.fromJson(json['settings']),
    );
  }
}
