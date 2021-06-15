part of '../polar.dart';

class PolarEcgData {
  final int timeStamp;
  final List<int> samples;

  PolarEcgData._fromJson(Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples = (json['samples'] as List).map((e) => e as int).toList();
}

class PolarAccData {
  final int timeStamp;
  final List<List<int>> samples;

  PolarAccData._fromJson(Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples = (json['samples'] as List)
            .map((e) => (e as List).map((e) => e as int).toList())
            .toList();
}

class PolarExerciseData {
  final int interval;
  final List<int> samples;

  PolarExerciseData._fromJson(Map<String, dynamic> json)
      : interval = json['interval'],
        samples = (json['samples'] as List).map((e) => e as int).toList();
}

// class PolarExerciseEntryCodable TODO

class PolarGyroData {
  final int timeStamp;
  final List<List<double>> samples;

  PolarGyroData._fromJson(Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples = (json['samples'] as List)
            .map((e) => (e as List).map((e) => e as double).toList())
            .toList();
}

// class PolarHrBroadcastDataCodable TODO

class PolarMagnetometerData {
  final int timeStamp;
  final List<List<double>> samples;

  PolarMagnetometerData._fromJson(Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples = (json['samples'] as List)
            .map((e) => (e as List).map((e) => e as double).toList())
            .toList();
}

class PolarOhrData {
  final int timeStamp;
  final OhrDataType type;
  final List<List<int>> samples;

  PolarOhrData._fromJson(Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        type = json['type'], // TODO
        samples = (json['samples'] as List)
            .map((e) => (e as List).map((e) => e as int).toList())
            .toList();
}

class PolarPpiData {
  final int timeStamp;
  final List<PolarPpiSample> samples;

  PolarPpiData._fromJson(Map<String, dynamic> json)
      : timeStamp = json['timeStamp'],
        samples = (json['samples'] as List)
            .map((e) => PolarPpiSample._fromJson(e))
            .toList();
}
