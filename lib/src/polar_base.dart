import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/src/model/device_streaming_feature.dart';
import 'package:polar/src/model/polar_device_info.dart';
import 'package:polar/src/model/polar_hr_data.dart';
import 'package:polar/src/model/polar_sensor_setting.dart';
import 'package:polar/src/model/polar_streaming.dart';
import 'package:polar/src/events.dart';

/// Flutter implementation of the [PolarBleSdk]
class Polar {
  static const MethodChannel _channel = MethodChannel('polar');

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

  /// helper to ask ble power state
  Stream<bool> get blePowerStateStream => _blePowerStateStreamController.stream;

  /// Device connection has been established.
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceConnectedStream =>
      _deviceConnectedStreamController.stream;

  /// Callback when connection attempt is started to device
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceConnectingStream =>
      _deviceConnectingStreamController.stream;

  /// Connection lost to device.
  /// If PolarBleApi#disconnectFromPolarDevice is not called, a new connection attempt is dispatched automatically.
  ///
  /// - Parameter identifier: Polar device info
  Stream<PolarDeviceInfo> get deviceDisconnectedStream =>
      _deviceDisconnectedStreamController.stream;

  /// feature ready callback
  Stream<PolarStreamingFeaturesReadyEvent> get streamingFeaturesReadyStream =>
      _streamingFeaturesReadyStreamController.stream;

  /// sdk mode feature available in this device and ready for usage callback
  Stream<String> get sdkModeFeatureAvailableStream =>
      _sdkModeFeatureAvailableStreamController.stream;

  /// Device HR feature is ready. HR transmission is starting in a short while.
  ///
  /// - Parameter identifier: Polar device id
  Stream<String> get hrFeatureReadyStream =>
      _hrFeatureReadyStreamController.stream;

  ///  Received DIS info.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - fwVersion: firmware version in format major.minor.patch
  Stream<PolarDisInformationEvent> get disInformationStream =>
      _disInformationStreamController.stream;

  /// Battery level received from device.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  ///   - batteryLevel: battery level in precentage 0-100%
  Stream<PolarBatteryLevelEvent> get batteryLevelStream =>
      _batteryLevelStreamController.stream;

  /// HR notification received. Notice when using OH1 and PPI stream is started this callback will produce 0 hr.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  Stream<PolarHeartRateEvent> get heartRateStream =>
      _heartRateStreamController.stream;

  /// Device file transfer protocol is ready.
  /// Notice all file transfer operations are preferred to be done at beginning of the connection
  ///
  /// - Parameter identifier: polar device id
  Stream<String> get ftpFeatureReadyStream =>
      _ftpFeatureReadyStreamController.stream;

  /// Will request location permission on Android S+ if false
  final bool bluetoothScanNeverForLocation;

  /// Initialize the Polar API
  ///
  /// DartDocs are copied from the iOS version of the SDK and are only included for reference
  ///
  /// The plugin will request location permission on Android S+ if [bluetoothScanNeverForLocation] is false
  Polar({this.bluetoothScanNeverForLocation = true}) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'ecgDataReceived':
          _ecgStreamController.add(
            PolarEcgData.fromJson(
              call.arguments[0],
              jsonDecode(call.arguments[1]),
            ),
          );
          return;
        case 'accDataReceived':
          _accStreamController.add(
            PolarAccData.fromJson(
              call.arguments[0],
              jsonDecode(call.arguments[1]),
            ),
          );
          return;
        case 'gyroDataReceived':
          _gyroStreamController.add(
            PolarGyroData.fromJson(
              call.arguments[0],
              jsonDecode(call.arguments[1]),
            ),
          );
          return;
        case 'magnetometerDataReceived':
          _magnetometerStreamController.add(
            PolarMagnetometerData.fromJson(
              call.arguments[0],
              jsonDecode(call.arguments[1]),
            ),
          );
          return;
        case 'ohrDataReceived':
          _ohrStreamController.add(
            PolarOhrData.fromJson(
              call.arguments[0],
              jsonDecode(call.arguments[1]),
            ),
          );
          return;
        case 'ohrPPIReceived':
          _ohrPPIStreamController.add(
            PolarPpiData.fromJson(
              call.arguments[0],
              jsonDecode(call.arguments[1]),
            ),
          );
          return;
        case 'blePowerStateChanged':
          _blePowerStateStreamController.add(call.arguments);
          return;
        case 'deviceConnected':
          _deviceConnectedStreamController
              .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          return;
        case 'deviceConnecting':
          _deviceConnectingStreamController
              .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          return;
        case 'deviceDisconnected':
          _deviceDisconnectedStreamController
              .add(PolarDeviceInfo.fromJson(jsonDecode(call.arguments)));
          return;
        case 'streamingFeaturesReady':
          _streamingFeaturesReadyStreamController.add(
            PolarStreamingFeaturesReadyEvent(
              call.arguments[0],
              (jsonDecode(call.arguments[1]) as List)
                  .map((e) => DeviceStreamingFeatureExtension.fromJson(e))
                  .toList(),
            ),
          );
          return;
        case 'sdkModeFeatureAvailable':
          _sdkModeFeatureAvailableStreamController.add(call.arguments);
          return;
        case 'hrFeatureReady':
          _hrFeatureReadyStreamController.add(call.arguments);
          return;
        case 'disInformationReceived':
          _disInformationStreamController.add(
            PolarDisInformationEvent(
              call.arguments[0],
              call.arguments[1],
              call.arguments[2],
            ),
          );
          return;
        case 'batteryLevelReceived':
          _batteryLevelStreamController.add(
            PolarBatteryLevelEvent(
              call.arguments[0],
              call.arguments[1],
            ),
          );
          return;
        case 'hrNotificationReceived':
          _heartRateStreamController.add(
            PolarHeartRateEvent(
              call.arguments[0],
              PolarHrData.fromJson(jsonDecode(call.arguments[1])),
            ),
          );
          return;
        case 'polarFtpFeatureReady':
          _ftpFeatureReadyStreamController.add(call.arguments);
          return;
        default:
          throw UnimplementedError(call.method);
      }
    });
  }

  /// Request a connection to a Polar device. Invokes `PolarBleApiObservers` polarDeviceConnected.
  /// - Parameter identifier: Polar device id printed on the sensor/device or UUID.
  /// - Throws: InvalidArgument if identifier is invalid polar device id or invalid uuid
  ///
  /// Will request the necessary permissions if [requestPermissions] is true
  Future<void> connectToDevice(
    String identifier, {
    bool requestPermissions = true,
  }) async {
    if (requestPermissions) {
      await this.requestPermissions();
    }

    unawaited(_channel.invokeMethod('connectToDevice', identifier));
  }

  /// Request the necessary permissions on Android
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidDeviceInfo.version.sdkInt;

      // If we are on Android M+
      if (sdkInt != null && sdkInt >= 23) {
        // If we are on an Android version before S or bluetooth scan is used to derive location
        if (sdkInt < 31 || !bluetoothScanNeverForLocation) {
          await Permission.location.request();
        }
        // If we are on Android S+
        if (sdkInt >= 31) {
          await Permission.bluetoothScan.request();
          await Permission.bluetoothConnect.request();
        }
      }
    }
  }

  /// Disconnect from the current Polar device.
  ///
  /// - Parameter identifier: Polar device id
  /// - Throws: InvalidArgument if identifier is invalid polar device id or invalid uuid
  void disconnectFromDevice(String identifier) {
    _channel.invokeMethod('disconnectFromDevice', identifier);
  }

  ///  Request the stream settings available in current operation mode. This request shall be used before the stream is started
  ///  to decide currently available settings. The available settings depend on the state of the device. For example, if any stream(s)
  ///  or optical heart rate measurement is already enabled, then the device may limit the offer of possible settings for other stream feature.
  ///  Requires `polarSensorStreaming` feature.
  ///
  /// - Parameters:
  ///   - identifier: polar device id
  ///   - feature: selected feature from`DeviceStreamingFeature`
  /// - Returns: Single stream
  ///   - success: once after settings received from device
  ///   - onError: see `PolarErrors` for possible errors invoked
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

  /// Start the ECG (Electrocardiography) stream. ECG stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarEcgData`
  ///   - onError: see `PolarErrors` for possible errors invoked
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

    unawaited(
      _channel.invokeMethod('startEcgStreaming', [
        identifier,
        jsonEncode(settings),
      ]),
    );
  }

  ///  Start ACC (Accelerometer) stream. ACC stream is stopped if the connection is closed, error occurs or stream is disposed.
  ///  Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarAccData`
  ///   - onError: see `PolarErrors` for possible errors invoked
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

    unawaited(
      _channel.invokeMethod('startAccStreaming', [
        identifier,
        jsonEncode(settings),
      ]),
    );
  }

  /// Start Gyro stream. Gyro stream is stopped if the connection is closed, error occurs during start or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
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

    unawaited(
      _channel.invokeMethod('startGyroStreaming', [
        identifier,
        jsonEncode(settings),
      ]),
    );
  }

  /// Start magnetometer stream. Magnetometer stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
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

    unawaited(
      _channel.invokeMethod('startMagnetometerStreaming', [
        identifier,
        jsonEncode(settings),
      ]),
    );
  }

  /// Start OHR (Optical heart rate) PPG (Photoplethysmography) stream. PPG stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Requires `polarSensorStreaming` feature. Before starting the stream it is recommended to query the available settings using `requestStreamSettings`
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarOhrData`
  ///   - onError: see `PolarErrors` for possible errors invoked
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

    unawaited(
      _channel.invokeMethod('startOhrStreaming', [
        identifier,
        jsonEncode(settings),
      ]),
    );
  }

  /// Start OHR (Optical heart rate) PPI (Pulse to Pulse interval) stream.
  /// PPI stream is stopped if the connection is closed, error occurs or stream is disposed.
  /// Notice that there is a delay before PPI data stream starts. Requires `polarSensorStreaming` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarPpiData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarPpiData> startOhrPPIStreaming(String identifier) {
    _channel.invokeMethod('startOhrPPIStreaming', identifier);
    return _ohrPPIStreamController.stream
        .where((e) => e.identifier == identifier);
  }
}
