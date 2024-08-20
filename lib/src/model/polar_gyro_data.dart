import 'package:json_annotation/json_annotation.dart';

part 'polar_gyro_data.g.dart';

@JsonSerializable()
class PolarGyroData {
  final int timeStamp;
  final List<GyroSample> samples;

  PolarGyroData(this.timeStamp, this.samples);

  factory PolarGyroData.fromJson(Map<String, dynamic> json) =>
      _$PolarGyroDataFromJson(json);
  Map<String, dynamic> toJson() => _$PolarGyroDataToJson(this);
}

@JsonSerializable()
class GyroSample {
  final int timeStamp;
  final double x;
  final double y;
  final double z;

  GyroSample(this.timeStamp, this.x, this.y, this.z);

  factory GyroSample.fromJson(Map<String, dynamic> json) =>
      _$GyroSampleFromJson(json);
  Map<String, dynamic> toJson() => _$GyroSampleToJson(this);
}
