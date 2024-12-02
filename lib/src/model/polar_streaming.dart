import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/convert.dart';
import 'package:polar/src/model/ppg_data_type.dart';

part 'polar_streaming.g.dart';

/// Base class for all streaming data
@JsonSerializable(genericArgumentFactories: true)
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
      case const (PolarHrSample):
        return _fromJson(json, _$PolarHrSampleFromJson);
      case const (PolarEcgSample):
        return _fromJson(json, _$PolarEcgSampleFromJson);
      case const (PolarAccSample):
        return _fromJson(json, _$PolarAccSampleFromJson);
      case const (PolarGyroSample):
        return _fromJson(json, _$PolarGyroSampleFromJson);
      case const (PolarMagnetometerSample):
        return _fromJson(json, _$PolarMagnetometerSampleFromJson);
      case const (PolarPpiSample):
        return _fromJson(json, _$PolarPpiSampleFromJson);
      case const (PolarTemperatureData):
        return _fromJson(json, _$PolarTemperatureSampleFromJson);
      case const (PolarPressureData):
        return _fromJson(json, _$PolarPressureSampleFromJson);
      default:
        throw UnsupportedError('Unsupported type: $T');
    }
  }

  Map<String, dynamic> _toJson(Function toJsonT) =>
      _$PolarStreamingDataToJson(this, (dynamic e) => toJsonT(e));

  /// Convert to json
  Map<String, dynamic> toJson() {
    switch (T) {
      case const (PolarHrSample):
        return _toJson(_$PolarHrSampleToJson);
      case const (PolarEcgSample):
        return _toJson(_$PolarEcgSampleToJson);
      case const (PolarAccSample):
        return _toJson(_$PolarAccSampleToJson);
      case const (PolarGyroSample):
        return _toJson(_$PolarGyroSampleToJson);
      case const (PolarMagnetometerSample):
        return _toJson(_$PolarMagnetometerSampleToJson);
      case const (PolarPpiSample):
        return _toJson(_$PolarPpiSampleToJson);
      case const (PolarTemperatureData):
        return _toJson(_$PolarTemperatureSampleToJson);
      case const (PolarPressureData):
        return _toJson(_$PolarPressureSampleToJson);
      default:
        throw UnsupportedError('Unsupported type: $T');
    }
  }
}

/// Polar HR sample
@JsonSerializable()
class PolarHrSample {
  /// hr in BPM
  final int hr;

  /// rrs RR interval in ms.
  final List<int> rrsMs;

  /// contact status between the device and the users skin
  final bool contactStatus;

  /// contactSupported if contact is supported
  final bool contactStatusSupported;

  /// Constructor
  PolarHrSample({
    required this.hr,
    required this.rrsMs,
    required this.contactStatus,
    required this.contactStatusSupported,
  });
}

/// Polar HR data
typedef PolarHrData = PolarStreamingData<PolarHrSample>;

/// Polar ecg sample
@JsonSerializable()
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
@JsonSerializable()
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

  /// From json
  factory PolarAccSample.fromJson(Map<String, dynamic> json) =>
      _$PolarAccSampleFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarAccSampleToJson(this);
}

/// Polar acc data
typedef PolarAccData = PolarStreamingData<PolarAccSample>;

/// Polar gyro sample
@JsonSerializable()
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
@JsonSerializable()
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
@JsonSerializable()
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

  /// To json
  Map<String, dynamic> toJson() => _$PolarPpgSampleToJson(this);
}

/// Polar ppg data
@JsonSerializable()
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

  /// To json
  @override
  Map<String, dynamic> toJson() => _$PolarPpgDataToJson(this);
}

/// Polar ppi sample
@JsonSerializable()
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

  /// From json
  factory PolarPpiSample.fromJson(Map<String, dynamic> json) =>
      _$PolarPpiSampleFromJson(json);

  /// To json
  Map<String, dynamic> toJson() => _$PolarPpiSampleToJson(this);
}

/// Polar ppi data
typedef PolarPpiData = PolarStreamingData<PolarPpiSample>;

/// Polar temperature sample
@JsonSerializable()
class PolarTemperatureSample {
  /// moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

  /// temperature value in celsius
  final double temperature;

  /// Constructor
  PolarTemperatureSample({
    required this.timeStamp,
    required this.temperature,
  });
}

/// Polar temperature data
typedef PolarTemperatureData = PolarStreamingData<PolarTemperatureSample>;

/// Polar pressure sample
@JsonSerializable()
class PolarPressureSample {
  /// moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  @PolarSampleTimestampConverter()
  final DateTime timeStamp;

  /// pressure value in pascal
  final double pressure;

  /// Constructor
  PolarPressureSample({
    required this.timeStamp,
    required this.pressure,
  });
}

/// Polar pressure data
typedef PolarPressureData = PolarStreamingData<PolarPressureSample>;

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
