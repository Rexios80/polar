import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/model/xyz.dart';
import 'package:recase/recase.dart';

part 'polar_api_observer.dart';
part 'model/device_streaming_feature.dart';
part 'model/polar_device_info.dart';
part 'model/polar_hr_data.dart';
part 'model/polar_streaming.dart';
part 'model/ohr_data_type.dart';
part 'model/polar_ohr_ppi_sample.dart';
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
            (jsonDecode(call.arguments[1]) as List)
                .map((e) => DeviceStreamingFeatureExtension.fromJson(e))
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

  /// Connect to a device with the given [identifier]
  void connectToDevice(String identifier) async {
    if (Platform.isAndroid) {
      await Permission.location.request();
    }

    _channel.invokeMethod('connectToDevice', identifier);
  }

  /// Disconnect from a device with the given [identifier]
  void disconnectFromDevice(String identifier) {
    _channel.invokeMethod('disconnectFromDevice', identifier);
  }

  Future<PolarSensorSetting> requestStreamSettings(
    String identifier,
    DeviceStreamingFeature feature,
  ) async {
    final response = await _channel.invokeMethod(
      'requestStreamSettings',
      [identifier, feature.toJson()],
    );
    final json = jsonDecode(response);
    return PolarSensorSetting.fromJson(json);
  }

  Stream<PolarEcgData> startEcgStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    _startEcgStreamingInternal(identifier, settings);
    return _ecgStreamController.stream;
  }

  void _startEcgStreamingInternal(
    String identifier,
    PolarSensorSetting? settings,
  ) async {
    settings ??= await requestStreamSettings(
      identifier,
      DeviceStreamingFeature.ecg,
    );

    _channel.invokeMethod('startEcgStreaming', [
      identifier,
      jsonEncode(settings),
    ]);
  }

  Stream<PolarAccData> startAccStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    _startAccStreamingInternal(identifier);
    return _accStreamController.stream;
  }

  void _startAccStreamingInternal(
    String identifier, {
    PolarSensorSetting? settings,
  }) async {
    settings ??= await requestStreamSettings(
      identifier,
      DeviceStreamingFeature.acc,
    );

    _channel.invokeMethod('startAccStreaming', [
      identifier,
      jsonEncode(settings),
    ]);
  }

  Stream<PolarGyroData> startGyroStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    _startGyroStreamingInternal(identifier, settings);
    return _gyroStreamController.stream;
  }

  void _startGyroStreamingInternal(
    String identifier,
    PolarSensorSetting? settings,
  ) async {
    settings ??= await requestStreamSettings(
      identifier,
      DeviceStreamingFeature.gyro,
    );

    _channel.invokeMethod('startGyroStreaming', [
      identifier,
      jsonEncode(settings),
    ]);
  }

  Stream<PolarMagnetometerData> startMagnetometerStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    _startMagnetometerStreamingInternal(identifier, settings);
    return _magnetometerStreamController.stream;
  }

  void _startMagnetometerStreamingInternal(
    String identifier,
    PolarSensorSetting? settings,
  ) async {
    settings ??= await requestStreamSettings(
      identifier,
      DeviceStreamingFeature.magnetometer,
    );

    _channel.invokeMethod('startMagnetometerStreaming', [
      identifier,
      jsonEncode(settings),
    ]);
  }

  Stream<PolarOhrData> startOhrStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    _startOhrStreamingInternal(identifier, settings);
    return _ohrStreamController.stream;
  }

  void _startOhrStreamingInternal(
    String identifier,
    PolarSensorSetting? settings,
  ) async {
    settings ??= await requestStreamSettings(
      identifier,
      DeviceStreamingFeature.ppg,
    );

    _channel.invokeMethod('startOhrStreaming', [
      identifier,
      jsonEncode(settings),
    ]);
  }

  Stream<PolarPpiData> startOhrPPIStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _ohrPPIStreamController.stream;
  }

  void _startOhrPPIStreamingInternal(
    String identifier,
    PolarSensorSetting? settings,
  ) async {
    settings ??= await requestStreamSettings(
      identifier,
      DeviceStreamingFeature.ppi,
    );

    _channel.invokeMethod('startOhrPPIStreaming', [
      identifier,
      jsonEncode(settings),
    ]);
  }
}
