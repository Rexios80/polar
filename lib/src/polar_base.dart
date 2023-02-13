import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/polar.dart';

/// Flutter implementation of the [PolarBleSdk]
class Polar {
  static const _channel = MethodChannel('polar');
  static const _searchChannel = EventChannel('polar/search');

  // Other data
  final _blePowerStateStreamController = StreamController<bool>.broadcast();
  final _bleSdkFeatureReadyStreamController =
      StreamController<PolarBleSdkFeatureReadyEvent>.broadcast();
  final _deviceConnectedStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _deviceConnectingStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _deviceDisconnectedStreamController =
      StreamController<PolarDeviceInfo>.broadcast();
  final _disInformationStreamController =
      StreamController<PolarDisInformationEvent>.broadcast();
  final _batteryLevelStreamController =
      StreamController<PolarBatteryLevelEvent>.broadcast();

  /// helper to ask ble power state
  Stream<bool> get blePowerStateStream => _blePowerStateStreamController.stream;

  /// feature ready callback
  Stream<PolarBleSdkFeatureReadyEvent> get bleSdkFeatureReadyStream =>
      _bleSdkFeatureReadyStreamController.stream;

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

  /// Will request location permission on Android S+ if false
  final bool bluetoothScanNeverForLocation;

  /// Initialize the Polar API
  ///
  /// DartDocs are copied from the iOS version of the SDK and are only included for reference
  ///
  /// The plugin will request location permission on Android S+ if [bluetoothScanNeverForLocation] is false
  Polar({this.bluetoothScanNeverForLocation = true}) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'blePowerStateChanged':
        _blePowerStateStreamController.add(call.arguments);
        return;
      case 'bleSdkFeatureReady':
        _bleSdkFeatureReadyStreamController.add(
          PolarBleSdkFeatureReadyEvent(
            call.arguments[0],
            PolarBleSdkFeature.fromJson(jsonDecode(call.arguments[1])),
          ),
        );
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
      default:
        throw UnimplementedError(call.method);
    }
  }

  /// Start searching for Polar device(s)
  ///
  /// - Parameter onNext: Invoked once for each device
  /// - Returns: Observable stream
  ///  - onNext: for every new polar device found
  Stream<PolarDeviceInfo> searchForDevice() {
    return _searchChannel.receiveBroadcastStream().map(
          (event) => PolarDeviceInfo.fromJson(jsonDecode(event)),
        );
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
      if (sdkInt >= 23) {
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
  Future<void> disconnectFromDevice(String identifier) {
    return _channel.invokeMethod('disconnectFromDevice', identifier);
  }

  ///  Get the data types available in this device for online streaming
  ///
  /// - Parameters:
  ///   - identifier: polar device id
  /// - Returns: Single stream
  ///   - success: set of available online streaming data types in this device
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<Set<PolarDeviceDataType>> getAvailableOnlineStreamDataTypes(
    String identifier,
  ) async {
    final response = await _channel.invokeListMethod(
      'getAvailableOnlineStreamDataTypes',
      identifier,
    );
    if (response == null) return {};
    return response.map(PolarDeviceDataType.fromJson).toSet();
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
    PolarDeviceDataType feature,
  ) async {
    final response = await _channel.invokeMethod(
      'requestStreamSettings',
      [identifier, feature.toJson()],
    );
    return PolarSensorSetting.fromJson(jsonDecode(response));
  }

  Stream<Map<String, dynamic>> _startStreaming(
    PolarDeviceDataType feature,
    String identifier, {
    PolarSensorSetting? settings,
  }) async* {
    assert(settings == null || settings.isSelection);

    final channelName = 'polar/streaming/$identifier/${feature.name}';

    await _channel.invokeMethod('createStreamingChannel', [
      channelName,
      identifier,
      feature.toJson(),
    ]);

    if (settings == null && feature != PolarDeviceDataType.ppi) {
      final availableSettings = await requestStreamSettings(
        identifier,
        feature,
      );
      settings = availableSettings.maxSettings();
    }

    yield* EventChannel(channelName)
        .receiveBroadcastStream(jsonEncode(settings))
        .cast<String>()
        .map(jsonDecode)
        .cast<Map<String, dynamic>>();
  }

  /// Start heart rate stream. Heart rate stream is stopped if the connection is closed,
  /// error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarHrData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarHrData> startHrStreaming(String identifier) {
    return _startStreaming(PolarDeviceDataType.hr, identifier)
        .map(PolarHrData.fromJson);
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
    return _startStreaming(
      PolarDeviceDataType.ecg,
      identifier,
      settings: settings,
    ).map(PolarEcgData.fromJson);
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
    return _startStreaming(
      PolarDeviceDataType.acc,
      identifier,
      settings: settings,
    ).map(PolarAccData.fromJson);
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
    return _startStreaming(
      PolarDeviceDataType.gyro,
      identifier,
      settings: settings,
    ).map(PolarGyroData.fromJson);
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
    return _startStreaming(
      PolarDeviceDataType.magnetometer,
      identifier,
      settings: settings,
    ).map(PolarMagnetometerData.fromJson);
  }

  /// Start optical sensor PPG (Photoplethysmography) stream. PPG stream is stopped if the connection is closed, error occurs or stream is disposed.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - settings: selected settings to start the stream
  /// - Returns: Observable stream
  ///   - onNext: for every air packet received. see `PolarOhrData`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Stream<PolarPpgData> startPpgStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDeviceDataType.ppg,
      identifier,
      settings: settings,
    ).map(PolarPpgData.fromJson);
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
  Stream<PolarPpiData> startPpiStreaming(String identifier) {
    return _startStreaming(PolarDeviceDataType.ppi, identifier)
        .map(PolarPpiData.fromJson);
  }

  /// Request start recording. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or UUID
  ///   - exerciseId: unique identifier for for exercise entry length from 1-64 bytes
  ///   - interval: recording interval to be used. Has no effect if `sampleType` is `SampleType.rr`
  ///   - sampleType: sample type to be used.
  /// - Returns: Completable stream
  ///   - success: recording started
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> startRecording(
    String identifier, {
    required String exerciseId,
    required RecordingInterval interval,
    required SampleType sampleType,
  }) {
    return _channel.invokeMethod(
      'startRecording',
      [identifier, exerciseId, interval.toJson(), sampleType.toJson()],
    );
  }

  /// Request stop for current recording. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or UUID
  /// - Returns: Completable stream
  ///   - success: recording stopped
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> stopRecording(String identifier) {
    return _channel.invokeMethod('stopRecording', identifier);
  }

  /// Request current recording status. Supported only by Polar H10. Requires `polarFileTransfer` feature.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id
  /// - Returns: Single stream
  ///   - success: see `PolarRecordingStatus`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarRecordingStatus> requestRecordingStatus(String identifier) async {
    final result =
        await _channel.invokeListMethod('requestRecordingStatus', identifier);

    return PolarRecordingStatus(ongoing: result![0], entryId: result[1]);
  }

  /// Api for fetching stored exercises list from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  /// - Returns: Observable stream
  ///   - onNext: see `PolarExerciseEntry`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<List<PolarExerciseEntry>> listExercises(String identifier) async {
    final result = await _channel.invokeListMethod('listExercises', identifier);
    if (result == null) {
      return [];
    }
    return result
        .cast<String>()
        .map((e) => PolarExerciseEntry.fromJson(jsonDecode(e)))
        .toList();
  }

  /// Api for fetching a single exercise from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - entry: single exercise entry to be fetched
  /// - Returns: Single stream
  ///   - success: invoked after exercise data has been fetched from the device. see `PolarExerciseEntry`
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<PolarExerciseData> fetchExercise(
    String identifier,
    PolarExerciseEntry entry,
  ) async {
    final result = await _channel
        .invokeMethod('fetchExercise', [identifier, jsonEncode(entry)]);
    return PolarExerciseData.fromJson(jsonDecode(result));
  }

  /// Api for removing single exercise from Polar H10 device. Requires `polarFileTransfer` feature. This API is working for Polar OH1 and Polar Verity Sense devices too, however in those devices recording of exercise requires that sensor is registered to Polar Flow account.
  ///
  /// - Parameters:
  ///   - identifier: Polar device id or device address
  ///   - entry: single exercise entry to be removed
  /// - Returns: Completable stream
  ///   - complete: entry successfully removed
  ///   - onError: see `PolarErrors` for possible errors invoked
  Future<void> removeExercise(String identifier, PolarExerciseEntry entry) {
    return _channel
        .invokeMethod('removeExercise', [identifier, jsonEncode(entry)]);
  }
}
