import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polar/polar.dart';

import 'package:polar/polar_platform_interface.dart';

/// An implementation of [PolarSdkPlatform] that uses method channels.
class MethodChannelPolarSdk extends PolarSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('polar');

  /// The event channel used to receive search events from the native platform.
  @visibleForTesting
  final searchChannel = const EventChannel('polar/search');

  final _blePowerState = StreamController<bool>.broadcast();
  final _sdkFeatureReady =
      StreamController<PolarSdkFeatureReadyEvent>.broadcast();
  final _deviceConnected = StreamController<PolarDeviceInfo>.broadcast();
  final _deviceConnecting = StreamController<PolarDeviceInfo>.broadcast();
  final _deviceDisconnected =
      StreamController<PolarDeviceDisconnectedEvent>.broadcast();
  final _disInformation =
      StreamController<PolarDisInformationEvent>.broadcast();
  final _batteryLevel = StreamController<PolarBatteryLevelEvent>.broadcast();

  @override
  Stream<bool> get blePowerState => _blePowerState.stream;

  @override
  Stream<PolarSdkFeatureReadyEvent> get sdkFeatureReady =>
      _sdkFeatureReady.stream;

  @override
  Stream<PolarDeviceInfo> get deviceConnected => _deviceConnected.stream;

  @override
  Stream<PolarDeviceInfo> get deviceConnecting => _deviceConnecting.stream;

  @override
  Stream<PolarDeviceDisconnectedEvent> get deviceDisconnected =>
      _deviceDisconnected.stream;

  @override
  Stream<PolarDisInformationEvent> get disInformation => _disInformation.stream;

  @override
  Stream<PolarBatteryLevelEvent> get batteryLevel => _batteryLevel.stream;

  /// Will request location permission on Android S+ if false
  final bool _bluetoothScanNeverForLocation;

  /// Constructor.
  MethodChannelPolarSdk(this._bluetoothScanNeverForLocation) {
    methodChannel.setMethodCallHandler(_handleMethodCall);
    init();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'blePowerStateChanged':
        _blePowerState.add(call.arguments as bool);
        return;
      case 'sdkFeatureReady':
        _sdkFeatureReady.add(
          PolarSdkFeatureReadyEvent(
            call.arguments[0] as String,
            PolarSdkFeature.fromJson(call.arguments[1]),
          ),
        );
        return;
      case 'deviceConnected':
        _deviceConnected.add(
          PolarDeviceInfo.fromJson(
            jsonDecode(call.arguments as String) as Map<String, dynamic>,
          ),
        );
        return;
      case 'deviceConnecting':
        _deviceConnecting.add(
          PolarDeviceInfo.fromJson(
            jsonDecode(call.arguments as String) as Map<String, dynamic>,
          ),
        );
        return;
      case 'deviceDisconnected':
        _deviceDisconnected.add(
          PolarDeviceDisconnectedEvent(
            PolarDeviceInfo.fromJson(
              jsonDecode(call.arguments[0] as String) as Map<String, dynamic>,
            ),
            call.arguments[1] as bool,
          ),
        );
        return;
      case 'disInformationReceived':
        _disInformation.add(
          PolarDisInformationEvent(
            call.arguments[0] as String,
            call.arguments[1] as String,
            call.arguments[2] as String,
          ),
        );
        return;
      case 'batteryLevelReceived':
        _batteryLevel.add(
          PolarBatteryLevelEvent(
            call.arguments[0] as String,
            call.arguments[1] as int,
          ),
        );
        return;
      default:
        throw UnimplementedError(call.method);
    }
  }

  Stream<Map<String, dynamic>> _startStreaming(
    PolarDataType feature,
    String identifier, {
    PolarSensorSetting? settings,
  }) async* {
    assert(settings == null || settings.isSelection);

    final channelName = 'polar/streaming/$identifier/${feature.name}';

    await methodChannel.invokeMethod('createStreamingChannel', [
      channelName,
      identifier,
      feature.toJson(),
    ]);

    if (settings == null && feature.supportsStreamSettings) {
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

  @override
  Stream<PolarDeviceInfo> searchForDevice() {
    return searchChannel.receiveBroadcastStream().map(
          (event) => PolarDeviceInfo.fromJson(
            jsonDecode(event as String) as Map<String, dynamic>,
          ),
        );
  }

  @override
  Future<void> connectToDevice(
    String identifier, {
    bool requestPermissions = true,
  }) async {
    if (requestPermissions) {
      await this.requestPermissions();
    }

    unawaited(methodChannel.invokeMethod('connectToDevice', identifier));
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidDeviceInfo.version.sdkInt;

      // If we are on Android M+
      if (sdkInt >= 23) {
        // If we are on an Android version before S or bluetooth scan is used to derive location
        if (sdkInt < 31 || !_bluetoothScanNeverForLocation) {
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

  @override
  Future<void> disconnectFromDevice(String identifier) {
    return methodChannel.invokeMethod('disconnectFromDevice', identifier);
  }

  @override
  Future<Set<PolarDataType>> getAvailableOnlineStreamDataTypes(
    String identifier,
  ) async {
    final response = await methodChannel.invokeMethod(
      'getAvailableOnlineStreamDataTypes',
      identifier,
    );
    if (response == null) return {};
    return (jsonDecode(response as String) as List)
        .map(PolarDataType.fromJson)
        .toSet();
  }

  @override
  Future<PolarSensorSetting> requestStreamSettings(
    String identifier,
    PolarDataType feature,
  ) async {
    final response = await methodChannel.invokeMethod(
      'requestStreamSettings',
      [identifier, feature.toJson()],
    );
    return PolarSensorSetting.fromJson(
      jsonDecode(response as String) as Map<String, dynamic>,
    );
  }

  @override
  Stream<PolarHrData> startHrStreaming(String identifier) {
    return _startStreaming(PolarDataType.hr, identifier)
        .map(PolarHrData.fromJson);
  }

  @override
  Stream<PolarEcgData> startEcgStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.ecg,
      identifier,
      settings: settings,
    ).map(PolarEcgData.fromJson);
  }

  @override
  Stream<PolarAccData> startAccStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.acc,
      identifier,
      settings: settings,
    ).map(PolarAccData.fromJson);
  }

  @override
  Stream<PolarGyroData> startGyroStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.gyro,
      identifier,
      settings: settings,
    ).map(PolarGyroData.fromJson);
  }

  @override
  Stream<PolarMagnetometerData> startMagnetometerStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.magnetometer,
      identifier,
      settings: settings,
    ).map(PolarMagnetometerData.fromJson);
  }

  @override
  Stream<PolarPpgData> startPpgStreaming(
    String identifier, {
    PolarSensorSetting? settings,
  }) {
    return _startStreaming(
      PolarDataType.ppg,
      identifier,
      settings: settings,
    ).map(PolarPpgData.fromJson);
  }

  @override
  Stream<PolarPpiData> startPpiStreaming(String identifier) {
    return _startStreaming(PolarDataType.ppi, identifier)
        .map(PolarPpiData.fromJson);
  }

  @override
  Future<void> startRecording(
    String identifier, {
    required String exerciseId,
    required RecordingInterval interval,
    required SampleType sampleType,
  }) {
    return methodChannel.invokeMethod(
      'startRecording',
      [identifier, exerciseId, interval.toJson(), sampleType.toJson()],
    );
  }

  @override
  Future<void> stopRecording(String identifier) {
    return methodChannel.invokeMethod('stopRecording', identifier);
  }

  @override
  Future<PolarRecordingStatus> requestRecordingStatus(String identifier) async {
    final result = await methodChannel.invokeListMethod<dynamic>(
      'requestRecordingStatus',
      identifier,
    );

    return PolarRecordingStatus(
      ongoing: result![0] as bool,
      entryId: result[1] as String,
    );
  }

  @override
  Future<List<PolarExerciseEntry>> listExercises(String identifier) async {
    final result = await methodChannel.invokeListMethod<String>(
      'listExercises',
      identifier,
    );
    if (result == null) {
      return [];
    }
    return result
        .map(
          (e) => PolarExerciseEntry.fromJson(
            jsonDecode(e) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<PolarExerciseData> fetchExercise(
    String identifier,
    PolarExerciseEntry entry,
  ) async {
    final result = await methodChannel
        .invokeMethod('fetchExercise', [identifier, jsonEncode(entry)]);
    return PolarExerciseData.fromJson(
      jsonDecode(result as String) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> removeExercise(String identifier, PolarExerciseEntry entry) {
    return methodChannel
        .invokeMethod('removeExercise', [identifier, jsonEncode(entry)]);
  }

  @override
  Future<void> setLedConfig(String identifier, LedConfig config) {
    return methodChannel
        .invokeMethod('setLedConfig', [identifier, jsonEncode(config)]);
  }

  @override
  Future<void> doFactoryReset(
    String identifier,
    bool preservePairingInformation,
  ) {
    return methodChannel.invokeMethod(
      'doFactoryReset',
      [identifier, preservePairingInformation],
    );
  }

  @override
  Future<void> enableSdkMode(String identifier) {
    return methodChannel.invokeMethod('enableSdkMode', identifier);
  }

  @override
  Future<void> disableSdkMode(String identifier) {
    return methodChannel.invokeMethod('disableSdkMode', identifier);
  }

  @override
  Future<bool> isSdkModeEnabled(String identifier) async {
    final result =
        await methodChannel.invokeMethod<bool>('isSdkModeEnabled', identifier);
    return result!;
  }

  @override
  Future<void> shutdown() async {
    await methodChannel.invokeMethod<bool>('shutdown');
  }

  @override
  Future<void> init() async {
    await methodChannel.invokeMethod<bool>('init');
  }
}
