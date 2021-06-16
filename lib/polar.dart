import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'util/snake_case.dart';

part 'polar_api_observer.dart';
part 'model/device_streaming_feature.dart';
part 'model/polar_device_info.dart';
part 'model/polar_hr_data.dart';
part 'model/polar_streaming.dart';
part 'model/ohr_data_type.dart';
part 'model/polar_ppi_sample.dart';
part 'model/polar_sensor_setting.dart';

class Polar {
  static const MethodChannel _channel = const MethodChannel('polar');

  final PolarApiObserver _observer;

  final _ecgStreamController = StreamController<PolarEcgData>.broadcast();
  final _accStreamController = StreamController<PolarAccData>.broadcast();
  final _gyroStreamController = StreamController<PolarGyroData>.broadcast();
  final _magnetometerStreamController =
      StreamController<PolarMagnetometerData>.broadcast();
  final _ohrStreamController = StreamController<PolarOhrData>.broadcast();
  final _ohrPPIStreamController = StreamController<PolarPpiData>.broadcast();

  /// Initialize the Polar API
  Polar(this._observer) {
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'ecgDataReceived':
          _ecgStreamController
              .add(PolarEcgData.fromJson(jsonDecode(call.arguments)));
          break;
        case 'accDataReceived':
          _accStreamController
              .add(PolarAccData.fromJson(jsonDecode(call.arguments)));
          break;
        case 'gyroDataReceived':
          _gyroStreamController
              .add(PolarGyroData.fromJson(jsonDecode(call.arguments)));
          break;
        case 'magnetometerDataReceived':
          _magnetometerStreamController
              .add(PolarMagnetometerData.fromJson(jsonDecode(call.arguments)));
          break;
        case 'ohrDataReceived':
          _ohrStreamController
              .add(PolarOhrData.fromJson(jsonDecode(call.arguments)));
          break;
        case 'ohrPPIReceived':
          _ohrPPIStreamController
              .add(PolarPpiData.fromJson(jsonDecode(call.arguments)));
          break;
        case 'blePowerStateChanged':
          _observer.blePowerStateChanged(call.arguments);
          break;
        case 'deviceConnected':
          _observer.deviceConnected(
              PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          break;
        case 'deviceConnecting':
          _observer.deviceConnecting(
              PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          break;
        case 'deviceDisconnected':
          _observer.deviceDisconnected(
              PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          break;
        case 'streamingFeaturesReady':
          _observer.streamingFeaturesReady(
            call.arguments[0],
            (call.arguments[1] as List<String>)
                .map((e) =>
                    EnumToString.fromString(
                        DeviceStreamingFeature.values, e.toLowerCase()) ??
                    DeviceStreamingFeature.error)
                .toList(),
          );
          break;
        case 'sdkModeFeatureAvailable':
          _observer.sdkModeFeatureAvailable(call.arguments);
          break;
        case 'hrFeatureReady':
          _observer.hrFeatureReady(call.arguments);
          break;
        case 'disInformationReceived':
          _observer.disInformationReceived(
            call.arguments[0],
            call.arguments[1],
            call.arguments[2],
          );
          break;
        case 'batteryLevelReceived':
          _observer.batteryLevelReceived(
            call.arguments[0],
            call.arguments[1],
          );
          break;
        case 'hrNotificationReceived':
          _observer.hrNotificationReceived(
            call.arguments[0],
            PolarHrData.fromJson(jsonDecode(call.arguments[1])),
          );
          break;
        case 'polarFtpFeatureReady':
          _observer.polarFtpFeatureReady(call.arguments);
          break;
      }

      return Future.value();
    });
  }

  /// Connect to a device with the given [deviceId]
  void connectToDevice(String deviceId) async {
    if (Platform.isAndroid) {
      await Permission.location.request();
    }

    _channel.invokeMethod('connectToDevice', deviceId);
  }

  /// Disconnect from a device with the given [deviceId]
  void disconnectFromDevice(String deviceId) {
    _channel.invokeMethod('disconnectFromDevice', deviceId);
  }

  Stream<PolarEcgData> startEcgStreaming(
    String deviceId,
    PolarSensorSetting settings,
  ) {
    _channel.invokeMethod('startEcgStreaming', [
      deviceId,
      jsonEncode(settings),
    ]);
    return _ecgStreamController.stream;
  }

  Stream<PolarAccData> startAccStreaming(
    String deviceId,
    PolarSensorSetting settings,
  ) {
    _channel.invokeMethod('startAccStreaming', [
      deviceId,
      jsonEncode(settings),
    ]);
    return _accStreamController.stream;
  }

  Stream<PolarGyroData> startGyroStreaming(
    String deviceId,
    PolarSensorSetting settings,
  ) {
    _channel.invokeMethod('startGyroStreaming', [
      deviceId,
      jsonEncode(settings),
    ]);
    return _gyroStreamController.stream;
  }

  Stream<PolarMagnetometerData> startMagnetometerStreaming(
    String deviceId,
    PolarSensorSetting settings,
  ) {
    _channel.invokeMethod('startMagnetometerStreaming', [
      deviceId,
      jsonEncode(settings),
    ]);
    return _magnetometerStreamController.stream;
  }

  Stream<PolarOhrData> startOhrStreaming(
    String deviceId,
    PolarSensorSetting settings,
  ) {
    _channel.invokeMethod('startOhrStreaming', [
      deviceId,
      jsonEncode(settings),
    ]);
    return _ohrStreamController.stream;
  }

  Stream<PolarPpiData> startOhrPPIStreaming(
    String deviceId,
    PolarSensorSetting settings,
  ) {
    _channel.invokeMethod('startOhrPPIStreaming', [
      deviceId,
      jsonEncode(settings),
    ]);
    return _ohrPPIStreamController.stream;
  }
}
