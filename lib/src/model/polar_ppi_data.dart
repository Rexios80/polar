import 'package:json_annotation/json_annotation.dart';

part 'polar_ppi_data.g.dart';

@JsonSerializable()
class PolarPpiData {
  final int timeStamp;
  final List<PpiSample> samples;

  PolarPpiData(this.timeStamp, this.samples);

  factory PolarPpiData.fromJson(Map<String, dynamic> json) =>
      _$PolarPpiDataFromJson(json);
  Map<String, dynamic> toJson() => _$PolarPpiDataToJson(this);
}

@JsonSerializable()
class PpiSample {
  final int hr;
  final int ppInMs;
  final int ppErrorEstimate;
  final int blockerBit;
  final int skinContactStatus;
  final int skinContactSupported;

  PpiSample(this.hr, this.ppInMs, this.ppErrorEstimate, this.blockerBit,
      this.skinContactStatus, this.skinContactSupported);

  factory PpiSample.fromJson(Map<String, dynamic> json) =>
      _$PpiSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PpiSampleToJson(this);
}
