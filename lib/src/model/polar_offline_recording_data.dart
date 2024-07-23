import 'package:json_annotation/json_annotation.dart';
import 'package:polar/src/model/polar_device_data_type.dart';
import 'package:polar/src/model/polar_sensor_setting.dart';
// import 'polar_acc_data.dart';
// import 'polar_gyro_data.dart';
// import 'polar_magnetometer_data.dart';
// import 'polar_ppg_data.dart';
// import 'polar_ppi_data.dart';
import 'package:polar/src/model/polar_streaming.dart';

// import 'polar_streaming.dart';

part 'polar_offline_recording_data.g.dart';

@JsonSerializable()
class PolarOfflineRecordingData {
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson)
  final PolarDataType type;
  final int startTime;
  final PolarSensorSetting? settings;
  final PolarAccData? accData;
  final PolarGyroData? gyroData;
  final PolarMagnetometerData? magData;
  final PolarPpgData? ppgData;
  final PolarPpiData? ppiData;
  final PolarHrData? hrData;

  PolarOfflineRecordingData({
    required this.type,
    required this.startTime,
    this.settings,
    this.accData,
    this.gyroData,
    this.magData,
    this.ppgData,
    this.ppiData,
    this.hrData,
  });

  factory PolarOfflineRecordingData.fromJson(Map<String, dynamic> json) =>
      _$PolarOfflineRecordingDataFromJson(json);
  Map<String, dynamic> toJson() => _$PolarOfflineRecordingDataToJson(this);

  static PolarDataType _typeFromJson(dynamic json) {
    return PolarDataType.values[json as int];
  }

  static int _typeToJson(PolarDataType type) {
    return type.index;
  }
}
