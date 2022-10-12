import 'dart:io';

import 'package:polar/src/model/ohr_data_type.dart';
import 'package:polar/src/model/polar_ohr_ppi_sample.dart';
import 'package:polar/src/model/xyz.dart';

/// Polar Ecg data
class PolarEcgData {
  /// Polar device id
  final String identifier;

  /// Last sample timestamp in nanoseconds. Default epoch is 1.1.2000
  final int timeStamp;

  /// ecg sample in µVolts
  final List<int> samples;

  /// Create a [PolarEcgData] from json
  PolarEcgData.fromJson(this.identifier, Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples = (json['samples'] as List).cast<int>().toList();
}

/// Polar acc data
class PolarAccData {
  /// Polar device id
  final String identifier;

  /// Last sample timestamp in nanoseconds. Default epoch is 1.1.2000 for H10.
  final int timeStamp;

  /// Acceleration samples list x,y,z in millig signed value
  final List<Xyz> samples;

  /// Create a [PolarAccData] from json
  PolarAccData.fromJson(this.identifier, Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples =
            (json['samples'] as List).map((e) => Xyz.fromJson(e)).toList();
}

/// Polar gyro data
class PolarGyroData {
  /// Polar device id
  final String identifier;

  /// Last sample timestamp in nanoseconds.
  final int timeStamp;

  /// gyro samples list x,y,z in °/s signed value
  final List<Xyz> samples;

  /// Create a [PolarGyroData] from json
  PolarGyroData.fromJson(this.identifier, Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples =
            (json['samples'] as List).map((e) => Xyz.fromJson(e)).toList();
}

/// Polar magnetometer data
class PolarMagnetometerData {
  /// Polar device id
  final String identifier;

  /// Last sample timestamp in nanoseconds.
  final int timeStamp;

  /// in Gauss
  final List<Xyz> samples;

  /// Create a [PolarMagnetometerData] from json
  PolarMagnetometerData.fromJson(this.identifier, Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples =
            (json['samples'] as List).map((e) => Xyz.fromJson(e)).toList();
}

/// Polar Ohr data
class PolarOhrData {
  /// Polar device id
  final String identifier;

  /// Last sample timestamp in nanoseconds.
  final int timeStamp;

  /// source of OHR data
  final OhrDataType type;

  /// ppg(s) and ambient(s) samples list
  final List<List<int>> samples;

  /// Create a [PolarOhrData] from json
  PolarOhrData.fromJson(this.identifier, Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        type = OhrDataType.fromJson(json['type']),
        samples = Platform.isIOS
            ? (json['samples'] as List)
                .map((e) => (e as List).cast<int>().toList())
                .toList()
            : (json['samples'] as List)
                .map(
                  (e) => (e['channelSamples'] as List).cast<int>().toList(),
                )
                .toList();
}

/// Polar ppi data
class PolarPpiData {
  /// Polar device id
  final String identifier;

  /// timestamp N/A always 0
  final int timeStamp;

  /// List of [PolarOhrPpiSample]
  final List<PolarOhrPpiSample> samples;

  /// Create a [PolarPpiData] from json
  PolarPpiData.fromJson(this.identifier, Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples = (json['samples'] as List)
            .map((e) => PolarOhrPpiSample.fromJson(e))
            .toList();
}
