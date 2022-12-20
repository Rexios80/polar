import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/converters.dart';
import 'package:polar/src/model/ohr_data_type.dart';

part 'polar_streaming.g.dart';

/// Polar ecg sample
@JsonSerializable(createToJson: false)
class PolarEcgSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  final int timeStamp;

  /// Voltage value in µVolts
  final int voltage;

  /// Constructor
  PolarEcgSample({
    required this.timeStamp,
    required this.voltage,
  });

  /// From json
  factory PolarEcgSample.fromJson(Map<String, dynamic> json) =>
      _$PolarEcgSampleFromJson(json);
}

/// Polar ecg data
@JsonSerializable(createToJson: false)
class PolarEcgData {
  /// Ecg samples
  final List<PolarEcgSample> samples;

  /// Constructor
  PolarEcgData({
    required this.samples,
  });

  /// From json
  factory PolarEcgData.fromJson(Map<String, dynamic> json) =>
      _$PolarEcgDataFromJson(json);
}

/// Polar acc sample
@JsonSerializable(createToJson: false)
class PolarAccSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  final int timeStamp;

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
}

/// Polar acc data
@JsonSerializable(createToJson: false)
class PolarAccData {
  /// Acceleration samples list x,y,z in millig signed value
  final List<PolarAccSample> samples;

  /// Constructor
  PolarAccData({
    required this.samples,
  });

  /// From json
  factory PolarAccData.fromJson(Map<String, dynamic> json) =>
      _$PolarAccDataFromJson(json);
}

/// Polar gyro sample
@JsonSerializable(createToJson: false)
class PolarGyroSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  final int timeStamp;

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

  /// From json
  factory PolarGyroSample.fromJson(Map<String, dynamic> json) =>
      _$PolarGyroSampleFromJson(json);
}

/// Polar gyro data
@JsonSerializable(createToJson: false)
class PolarGyroData {
  /// Gyroscope samples
  final List<PolarGyroSample> samples;

  /// Constructor
  PolarGyroData({
    required this.samples,
  });

  /// From json
  factory PolarGyroData.fromJson(Map<String, dynamic> json) =>
      _$PolarGyroDataFromJson(json);
}

/// Polar magnetometer sample
@JsonSerializable(createToJson: false)
class PolarMagnetometerSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  final int timeStamp;

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

  /// From json
  factory PolarMagnetometerSample.fromJson(Map<String, dynamic> json) =>
      _$PolarMagnetometerSampleFromJson(json);
}

/// Polar magnetometer data
@JsonSerializable(createToJson: false)
class PolarMagnetometerData {
  /// Magnetometer samples
  final List<PolarMagnetometerSample> samples;

  /// Constructor
  PolarMagnetometerData({
    required this.samples,
  });

  /// From json
  factory PolarMagnetometerData.fromJson(Map<String, dynamic> json) =>
      _$PolarMagnetometerDataFromJson(json);
}

/// Polar ohr sample
@JsonSerializable(createToJson: false)
class PolarOhrSample {
  /// Moment sample is taken in nanoseconds. The epoch of timestamp is 1.1.2000
  final int timeStamp;

  /// The PPG (Photoplethysmography) raw value received from the optical sensor.
  /// Based on [OhrDataType] the amount of channels varies. Typically ppg(n)
  /// channel + n ambient(s).
  final List<int> channelSamples;

  /// Constructor
  PolarOhrSample({
    required this.timeStamp,
    required this.channelSamples,
  });

  /// From json
  factory PolarOhrSample.fromJson(Map<String, dynamic> json) =>
      _$PolarOhrSampleFromJson(json);
}

/// Polar ohr data
@JsonSerializable(createToJson: false)
class PolarOhrData {
  /// Type of data, which varies based on what is type of optical sensor used
  /// in the device
  @OhrDataTypeConverter()
  final OhrDataType type;

  /// Photoplethysmography samples
  final List<PolarOhrSample> samples;

  /// Constructor
  PolarOhrData({
    required this.type,
    required this.samples,
  });

  /// From json
  factory PolarOhrData.fromJson(Map<String, dynamic> json) =>
      _$PolarOhrDataFromJson(json);
}

/// Polar ppi sample
@JsonSerializable(createToJson: false)
class PolarOhrPpiSample {
  /// ppInMs Pulse to Pulse interval in milliseconds.
  /// The value indicates the quality of PP-intervals.
  /// When error estimate is below 10ms the PP-intervals are probably very accurate.
  /// Error estimate values over 30ms may be caused by movement artefact or too loose sensor-skin contact.
  final int ppi;

  /// ppErrorEstimate estimate of the expected absolute error in PP-interval in milliseconds
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
  PolarOhrPpiSample({
    required this.ppi,
    required this.errorEstimate,
    required this.hr,
    required this.blockerBit,
    required this.skinContactStatus,
    required this.skinContactSupported,
  });

  /// From json
  factory PolarOhrPpiSample.fromJson(Map<String, dynamic> json) =>
      _$PolarOhrPpiSampleFromJson(json);
}

/// Polar ppi data
@JsonSerializable(createToJson: false)
class PolarOhrPpiData {
  /// PPI samples
  final List<PolarOhrPpiSample> samples;

  /// Constructor
  PolarOhrPpiData({
    required this.samples,
  });

  /// From json
  factory PolarOhrPpiData.fromJson(Map<String, dynamic> json) =>
      _$PolarOhrPpiDataFromJson(json);
}
