import 'package:json_annotation/json_annotation.dart';

part 'polar_magnetometer_data.g.dart';

@JsonSerializable()
class PolarMagnetometerData {
  final int timeStamp;
  final List<MagnetometerSample> samples;

  PolarMagnetometerData(this.timeStamp, this.samples);

  factory PolarMagnetometerData.fromJson(Map<String, dynamic> json) =>
      _$PolarMagnetometerDataFromJson(json);
  Map<String, dynamic> toJson() => _$PolarMagnetometerDataToJson(this);
}

@JsonSerializable()
class MagnetometerSample {
  final int timeStamp;
  final double x;
  final double y;
  final double z;

  MagnetometerSample(this.timeStamp, this.x, this.y, this.z);

  factory MagnetometerSample.fromJson(Map<String, dynamic> json) =>
      _$MagnetometerSampleFromJson(json);
  Map<String, dynamic> toJson() => _$MagnetometerSampleToJson(this);
}
