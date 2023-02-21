import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/convert.dart';
import 'package:polar/src/model/ppg_data_type.dart';

part 'polar_streaming.g.dart';

/// Base class for all streaming data
@JsonSerializable(createToJson: false, genericArgumentFactories: true)
class PolarStreamingData<T> {
  /// Samples
  final List<T> samples;

  /// Constructor
  PolarStreamingData({
    required this.samples,
  });

  static PolarStreamingData<T> _fromJson<T>(
    Map<String, dynamic> json,
    dynamic Function(Map<String, dynamic>) fromJsonT,
  ) =>
      _$PolarStreamingDataFromJson(json, (dynamic e) => fromJsonT(e));

  /// Convert from json
  factory PolarStreamingData.fromJson(Map<String, dynamic> json) {
    switch (T) {
      case PolarHrSample:
        return _fromJson(json, _$PolarHrSampleFromJson);
      case PolarEcgSample:
        return _fromJson(json, _$PolarEcgSampleFromJson);
      case PolarAccSample:
        return _fromJson(json, _$PolarAccSampleFromJson);
      case PolarGyroSample:
        return _fromJson(json, _$PolarGyroSampleFromJson);
      case PolarMagnetometerSample:
        return _fromJson(json, _$PolarMagnetometerSampleFromJson);
      case PolarPpiSample:
        return _fromJson(json, _$PolarPpiSampleFromJson);
      default:
        throw UnsupportedError('Unsupported type: $T');
    }
  }
}

/// Polar HR sample
@JsonSerializable(createToJson: false)
class PolarHrSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

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
  PolarHrSample({
    required this.timeStamp,
    required this.hr,
    required this.rrs,
    required this.rrsMs,
    required this.contactStatus,
    required this.contactStatusSupported,
  });
}

Object? _readContactStatus(Map json, String key) => readPlatformValue(
      json,
      {
        TargetPlatform.iOS: 'contact',
        TargetPlatform.android: 'contactStatus',
      },
    );

Object? _readContactStatusSupported(Map json, String key) => readPlatformValue(
      json,
      {
        TargetPlatform.iOS: 'contactSupported',
        TargetPlatform.android: 'contactStatusSupported',
      },
    );

/// Polar HR data
typedef PolarHrData = PolarStreamingData<PolarHrSample>;

/// Polar ecg sample
@JsonSerializable(createToJson: false)
class PolarEcgSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

  /// Voltage value in µVolts
  final int voltage;

  /// Constructor
  PolarEcgSample({
    required this.timeStamp,
    required this.voltage,
  });
}

/// Polar ecg data
typedef PolarEcgData = PolarStreamingData<PolarEcgSample>;

/// Polar acc sample
@JsonSerializable(createToJson: false)
class PolarAccSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

  /// x axis value in millig (including gravity)
  final int x;

  /// y axis value in millig (including gravity)
  final int y;

  /// z axis value in millig (including gravity)
  final int z;

  /// Constructor
  PolarAccSample({
    required this.timeStamp,
    required this.x,
    required this.y,
    required this.z,
  });
}

/// Polar acc data
typedef PolarAccData = PolarStreamingData<PolarAccSample>;

/// Polar gyro sample
@JsonSerializable(createToJson: false)
class PolarGyroSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

  /// x axis value in deg/sec
  final double x;

  /// y axis value in deg/sec
  final double y;

  /// z axis value in deg/sec
  final double z;

  /// Constructor
  PolarGyroSample({
    required this.timeStamp,
    required this.x,
    required this.y,
    required this.z,
  });
}

/// Polar gyro data
typedef PolarGyroData = PolarStreamingData<PolarGyroSample>;

/// Polar magnetometer sample
@JsonSerializable(createToJson: false)
class PolarMagnetometerSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

  /// x axis value in Gauss
  final double x;

  /// y axis value in Gauss
  final double y;

  /// z axis value in Gauss
  final double z;

  /// Constructor
  PolarMagnetometerSample({
    required this.timeStamp,
    required this.x,
    required this.y,
    required this.z,
  });
}

/// Polar magnetometer data
typedef PolarMagnetometerData = PolarStreamingData<PolarMagnetometerSample>;

/// Polar ohr sample
@JsonSerializable(createToJson: false)
class PolarPpgSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

  /// The PPG (Photoplethysmography) raw value received from the optical sensor.
  /// Based on [PpgDataType] the amount of channels varies. Typically ppg(n)
  /// channel + n ambient(s).
  final List<int> channelSamples;

  /// Constructor
  PolarPpgSample({
    required this.timeStamp,
    required this.channelSamples,
  });

  /// From json
  factory PolarPpgSample.fromJson(Map<String, dynamic> json) =>
      _$PolarPpgSampleFromJson(json);
}

/// Polar ppg data
@JsonSerializable(createToJson: false)
class PolarPpgData extends PolarStreamingData<PolarPpgSample> {
  /// Type of data, which varies based on what is type of optical sensor used
  /// in the device
  @PpgDataTypeConverter()
  final PpgDataType type;

  /// Constructor
  PolarPpgData({
    required this.type,
    required super.samples,
  });

  /// From json
  factory PolarPpgData.fromJson(Map<String, dynamic> json) =>
      _$PolarPpgDataFromJson(json);
}

/// Polar ppi sample
@JsonSerializable(createToJson: false)
class PolarPpiSample {
  /// ppInMs Pulse to Pulse interval in milliseconds.
  /// The value indicates the quality of PP-intervals.
  /// When error estimate is below 10ms the PP-intervals are probably very accurate.
  /// Error estimate values over 30ms may be caused by movement artefact or too loose sensor-skin contact.
  @JsonKey(readValue: _readPpi)
  final int ppi;

  /// ppErrorEstimate estimate of the expected absolute error in PP-interval in milliseconds
  @JsonKey(readValue: _readErrorEstimate)
  final int errorEstimate;

  /// hr in BPM
  final int hr;

  /// blockerBit = 1 if PP measurement was invalid due to acceleration or other reason
  @PlatformBooleanConverter()
  final bool blockerBit;

  /// skinContactStatus = 0 if the device detects poor or no contact with the skin
  @PlatformBooleanConverter()
  final bool skinContactStatus;

  /// skinContactSupported = 1 if the Sensor Contact feature is supported
  @PlatformBooleanConverter()
  final bool skinContactSupported;

  /// Constructor
  PolarPpiSample({
    required this.ppi,
    required this.errorEstimate,
    required this.hr,
    required this.blockerBit,
    required this.skinContactStatus,
    required this.skinContactSupported,
  });
}

Object? _readErrorEstimate(Map json, String key) => readPlatformValue(
      json,
      {
        TargetPlatform.iOS: 'ppErrorEstimate',
        TargetPlatform.android: 'errorEstimate',
      },
    );

Object? _readPpi(Map json, String key) => readPlatformValue(
      json,
      {
        TargetPlatform.iOS: 'ppInMs',
        TargetPlatform.android: 'ppi',
      },
    );

/// Polar ppi data
typedef PolarPpiData = PolarStreamingData<PolarPpiSample>;
