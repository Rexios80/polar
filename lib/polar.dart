import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/model/xyz.dart';
import 'package:recase/recase.dart';

part 'model/device_streaming_feature.dart';
part 'model/polar_device_info.dart';
part 'model/polar_hr_data.dart';
part 'model/polar_streaming.dart';
part 'model/ohr_data_type.dart';
part 'model/polar_ohr_ppi_sample.dart';
part 'model/polar_sensor_setting.dart';
part 'events.dart';

class Polar {
  static const MethodChannel _channel = const MethodChannel('polar');

  // Streaming
  final _ecgStreamController = StreamController<PolarEcgData>.broadcast();
  final _accStreamController = StreamController<PolarAccData>.broadcast();
  final _gyroStreamController = StreamController<PolarGyroData>.broadcast();
  final _magnetometerStreamController =
      StreamController<PolarMagnetometerData>.broadcast();
  final _ohrStreamController = StreamController<PolarOhrData>.broadcast();
  final _ohrPPIStreamController = StreamController<PolarPpiData>.broadcast();

  // Other data
  final _blePowerStateStreamController = StreamController<bool>.broadcast();
  final _deviceConnectedStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _deviceConnectingStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _deviceDisconnectedStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _streamingFeaturesReadyStreamController =
      StreamController<PolarStreamingFeaturesReadyEvent>.broadcast();
  final _sdkModeFeatureAvailableStreamController =
      StreamController<String>.broadcast();
  final _hrFeatureReadyStreamController = StreamController<String>.broadcast();
  final _disInformationStreamController =
      StreamController<PolarDisInformationEvent>.broadcast();
  final _batteryLevelStreamController =
      StreamController<PolarBatteryLevelEvent>.broadcast();
  final _heartRateStreamController =
      StreamController<PolarHeartRateEvent>.broadcast();
  final _ftpFeatureReadyStreamController = StreamController<String>.broadcast();

  Stream<bool> get blePowerStateStream => _blePowerStateStreamController.stream;
  Stream<PolarDeviceInfo> get deviceConnectedStream =>
      _deviceConnectedStreamController.stream;
  Stream<PolarDeviceInfo> get deviceConnectingStream =>
      _deviceConnectingStreamController.stream;
  Stream<PolarDeviceInfo> get deviceDisconnectedStream =>
      _deviceDisconnectedStreamController.stream;
  Stream<PolarStreamingFeaturesReadyEvent> get streamingFeaturesReadyStream =>
      _streamingFeaturesReadyStreamController.stream;
  Stream<String> get sdkModeFeatureAvailableStream =>
      _sdkModeFeatureAvailableStreamController.stream;
  Stream<String> get hrFeatureReadyStream =>
      _hrFeatureReadyStreamController.stream;
  Stream<PolarDisInformationEvent> get disInformationStream =>
      _disInformationStreamController.stream;
  Stream<PolarBatteryLevelEvent> get batteryLevelStream =>
      _batteryLevelStreamController.stream;
  Stream<PolarHeartRateEvent> get heartRateStream =>
      _heartRateStreamController.stream;
  Stream<String> get ftpFeatureReadyStream =>
      _ftpFeatureReadyStreamController.stream;

  /// Initialize the Polar API
  Polar() {
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'ecgDataReceived':
          _ecgStreamController.add(PolarEcgData.fromJson(
            call.arguments[0],
            jsonDecode(call.arguments[1]),
          ));
          break;
        case 'accDataReceived':
          _accStreamController.add(PolarAccData.fromJson(
            call.arguments[0],
            jsonDecode(call.arguments[1]),
          ));
          break;
        case 'gyroDataReceived':
          _gyroStreamController.add(PolarGyroData.fromJson(
            call.arguments[0],
            jsonDecode(call.arguments[1]),
          ));
          break;
        case 'magnetometerDataReceived':
          _magnetometerStreamController.add(PolarMagnetometerData.fromJson(
            call.arguments[0],
            jsonDecode(call.arguments[1]),
          ));
          break;
        case 'ohrDataReceived':
          _ohrStreamController.add(PolarOhrData.fromJson(
            call.arguments[0],
            jsonDecode(call.arguments[1]),
          ));
          break;
        case 'ohrPPIReceived':
          _ohrPPIStreamController.add(PolarPpiData.fromJson(
            call.arguments[0],
            jsonDecode(call.arguments[1]),
          ));
          break;
        case 'blePowerStateChanged':
          _blePowerStateStreamController.add(call.arguments);
          break;
        case 'deviceConnected':
          _deviceConnectedStreamController
              .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          break;
        case 'deviceConnecting':
          _deviceConnectingStreamController
              .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          break;
        case 'deviceDisconnected':
          _deviceDisconnectedStreamController
              .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          break;
        case 'streamingFeaturesReady':
          _streamingFeaturesReadyStreamController.add(
            PolarStreamingFeaturesReadyEvent(
              call.arguments[0],
              (jsonDecode(call.arguments[1]) as List)
                  .map((e) => DeviceStreamingFeatureExtension.fromJson(e))
                  .toList(),
            ),
          );
          break;
        case 'sdkModeFeatureAvailable':
          _sdkModeFeatureAvailableStreamController.add(call.arguments);
          break;
        case 'hrFeatureReady':
          _hrFeatureReadyStreamController.add(call.arguments);
          break;
        case 'disInformationReceived':
          _disInformationStreamController.add(
            PolarDisInformationEvent(
              call.arguments[0],
              call.arguments[1],
              call.arguments[2],
            ),
          );
          break;
        case 'batteryLevelReceived':
          _batteryLevelStreamController.add(
            PolarBatteryLevelEvent(
              call.arguments[0],
              call.arguments[1],
            ),
          );
          break;
        case 'hrNotificationReceived':
          _heartRateStreamController.add(
            PolarHeartRateEvent(
              call.arguments[0],
              PolarHrData.fromJson(jsonDecode(call.arguments[1])),
            ),
          );
          break;
        case 'polarFtpFeatureReady':
          _ftpFeatureReadyStreamController.add(call.arguments);
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
    return _ecgStreamController.stream.where((e) => e.identifier == identifier);
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
    return _accStreamController.stream.where((e) => e.identifier == identifier);
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
    return _gyroStreamController.stream
        .where((e) => e.identifier == identifier);
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
    return _magnetometerStreamController.stream
        .where((e) => e.identifier == identifier);
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
    return _ohrStreamController.stream.where((e) => e.identifier == identifier);
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
    _startOhrPPIStreamingInternal(identifier, settings);
    return _ohrPPIStreamController.stream
        .where((e) => e.identifier == identifier);
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
