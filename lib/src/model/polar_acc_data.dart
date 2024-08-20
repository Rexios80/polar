import 'package:json_annotation/json_annotation.dart';

part 'polar_acc_data.g.dart';

@JsonSerializable()
class PolarAccData {
  final int timeStamp;
  final List<AccSample> samples;

  PolarAccData(this.timeStamp, this.samples);

  factory PolarAccData.fromJson(Map<String, dynamic> json) =>
      _$PolarAccDataFromJson(json);
  Map<String, dynamic> toJson() => _$PolarAccDataToJson(this);
}

@JsonSerializable()
class AccSample {
  final int timeStamp;
  final int x;
  final int y;
  final int z;

  AccSample(this.timeStamp, this.x, this.y, this.z);

  factory AccSample.fromJson(Map<String, dynamic> json) =>
      _$AccSampleFromJson(json);
  Map<String, dynamic> toJson() => _$AccSampleToJson(this);
}
