import 'package:json_annotation/json_annotation.dart';

part 'polar_ppg_data.g.dart';

@JsonSerializable()
class PolarPpgData {
  final String type;
  final List<PpgSample> samples;

  PolarPpgData(this.type, this.samples);

  factory PolarPpgData.fromJson(Map<String, dynamic> json) =>
      _$PolarPpgDataFromJson(json);
  Map<String, dynamic> toJson() => _$PolarPpgDataToJson(this);
}

@JsonSerializable()
class PpgSample {
  final int timeStamp;
  final List<int> channelSamples;

  PpgSample(this.timeStamp, this.channelSamples);

  factory PpgSample.fromJson(Map<String, dynamic> json) =>
      _$PpgSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PpgSampleToJson(this);
}
