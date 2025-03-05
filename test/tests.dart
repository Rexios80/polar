import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polar/polar.dart';
import 'package:uuid/uuid.dart';

final polar = Polar();

Future<void> requestPermissions() {
  debugPrint('''
**********************************************************************
* Accept the permission request on the device
**********************************************************************''');
  return polar.requestPermissions();
}

void testSearch(String identifier) {
  test('search', () async {
    await polar.searchForDevice().any((e) => e.deviceId == identifier);
    // Will fail by timeout if device is not found
  });
}

void testConnection(String identifier) {
  test('connection', () async {
    await polar.connectToDevice(identifier);

    final connecting = await polar.deviceConnecting.first;
    expect(connecting.deviceId, identifier);

    final connected = await polar.deviceConnected.first;
    expect(connected.deviceId, identifier);

    await polar.disconnectFromDevice(identifier);

    final disconnected = await polar.deviceDisconnected.first;
    expect(disconnected.info.deviceId, identifier);
  });
}

/// Ensure device connects
Future<void> connect(String identifier) async {
  await polar.connectToDevice(identifier);
  await polar.deviceConnected.first;
}

/// Ensure device disconnects
Future<void> disconnect(String identifier) async {
  await polar.disconnectFromDevice(identifier);
  await polar.deviceDisconnected.first;
}

void testBasicData(String identifier) {
  group('basic data', () {
    setUp(() async {
      await connect(identifier);
    });

    tearDown(() async {
      await disconnect(identifier);
    });

    test('disInformation', () async {
      final disInformation = await polar.disInformation.first;
      expect(disInformation.identifier, identifier);
    });

    test('batteryLevel', () async {
      final batteryEvent = await polar.batteryLevel.first;
      expect(batteryEvent.level, greaterThan(0));
    });
  });
}

void testBleSdkFeatures(
  String identifier, {
  required Set<PolarSdkFeature> features,
}) {
  test('Ble sdk features', () async {
    await connect(identifier);
    final available = await polar.sdkFeatureReady
        .take(features.length)
        .map((e) => e.feature)
        .toSet();
    expect(setEquals(available, features), true);
    await disconnect(identifier);
  });
}

void testStreaming(
  String identifier, {
  required Set<PolarDataType> features,
}) {
  group('streaming', () {
    setUpAll(() async {
      await connect(identifier);
      await polar.sdkFeatureReady
          .firstWhere((e) => e.feature == PolarSdkFeature.onlineStreaming);
      final available =
          await polar.getAvailableOnlineStreamDataTypes(identifier);
      expect(setEquals(available, features), true);
    });

    tearDownAll(() async {
      await disconnect(identifier);
    });

    test(
      'hr',
      () async {
        final hrData = await polar.startHrStreaming(identifier).first;
        expect(hrData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDataType.hr),
    );

    test(
      'ecg',
      () async {
        final ecgData = await polar.startEcgStreaming(identifier).first;
        expect(ecgData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDataType.ecg),
    );

    test(
      'acc',
      () async {
        final accData = await polar.startAccStreaming(identifier).first;
        expect(accData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDataType.acc),
    );

    test(
      'ppg',
      () async {
        final ppgData = await polar.startPpgStreaming(identifier).first;
        expect(ppgData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDataType.ppg),
    );

    test(
      'gyro',
      () async {
        final gyroData = await polar.startGyroStreaming(identifier).first;
        expect(gyroData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDataType.gyro),
    );

    test(
      'magnetometer',
      () async {
        final magnetometerData =
            await polar.startMagnetometerStreaming(identifier).first;
        expect(magnetometerData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDataType.magnetometer),
    );

    test(
      'ppi',
      () async {
        final ppiData = await polar.startPpiStreaming(identifier).first;
        expect(ppiData.samples.length, greaterThan(0));
      },
      skip: !features.contains(PolarDataType.ppi),
    );
  });
}

final exerciseId = const Uuid().v4();

void testRecording(String identifier, {bool wait = true}) {
  test('recording', () async {
    await connect(identifier);
    await polar.sdkFeatureReady.firstWhere(
      (e) => e.feature == PolarSdkFeature.h10ExerciseRecording,
    );

    //! Remove existing recordings (THIS IS DESTRUCTIVE)
    // Polar H10 can only store one recording at a time
    final entries1 = await polar.listExercises(identifier);
    for (final entry in entries1) {
      await polar.removeExercise(identifier, entry);
    }

    final status1 = await polar.requestRecordingStatus(identifier);
    expect(status1.ongoing, false);

    await polar.startRecording(
      identifier,
      exerciseId: exerciseId,
      interval: RecordingInterval.interval_1s,
      sampleType: SampleType.rr,
    );

    final status2 = await polar.requestRecordingStatus(identifier);
    expect(status2.entryId, exerciseId);
    expect(status2.ongoing, true);

    if (wait) {
      await Future.delayed(const Duration(seconds: 5));
    }
    await polar.stopRecording(identifier);

    final status3 = await polar.requestRecordingStatus(identifier);
    expect(status3.ongoing, false);

    final entries2 = await polar.listExercises(identifier);
    final entry = entries2.firstWhere((e) => e.entryId == exerciseId);
    expect(entry.entryId, exerciseId);

    final exercise = await polar.fetchExercise(identifier, entry);
    expect(exercise.samples.length, greaterThan(0));

    await polar.removeExercise(identifier, entry);

    final entries3 = await polar.listExercises(identifier);
    expect(entries3.any((e) => e.entryId == exerciseId), false);

    await disconnect(identifier);
  });
}

void testSdkMode(String identifier) {
  test('sdk mode', () async {
    await connect(identifier);

    final status1 = await polar.isSdkModeEnabled(identifier);
    expect(status1, false);

    await polar.enableSdkMode(identifier);
    final status2 = await polar.isSdkModeEnabled(identifier);
    expect(status2, true);

    await polar.disableSdkMode(identifier);
    final status3 = await polar.isSdkModeEnabled(identifier);
    expect(status3, false);

    await disconnect(identifier);
  });
}

void testMisc(String identifier, {required bool isVerity}) {
  test('misc', () async {
    await connect(identifier);
    // Wait to ensure device is connected (not sure why this is necessary)
    await Future.delayed(const Duration(seconds: 3));
    if (isVerity) {
      await polar.setLedConfig(
        identifier,
        LedConfig(ppiModeLedEnabled: false, sdkModeLedEnabled: false),
      );
      await polar.setLedConfig(
        identifier,
        LedConfig(ppiModeLedEnabled: true, sdkModeLedEnabled: true),
      );
    }

    await polar.doFactoryReset(identifier, false);
    await disconnect(identifier);
  });
}

void testAvailableOfflineRecordingDataTypes(String identifier) {
  test('Should test available offline recordings data types', () async {
    final mockDataTypes =
        jsonEncode(PolarDataType.values.map((e) => e.toJson()).toList());

    final dataTypes =
        await polar.getAvailableOfflineRecordingDataTypes(identifier);
    expect(dataTypes, mockDataTypes);
  });
}

void testOfflineRecording(String identifier) {
  test('Should test all offline recording functions', () async {
    final settings = await polar.requestOfflineRecordingSettings(
      identifier,
      PolarDataType.acc,
    );
    expect(settings != null, true);

    await polar.startOfflineRecording(
      identifier,
      PolarDataType.acc,
      settings: settings,
    );

    final recordingStatus = await polar.getOfflineRecordingStatus(identifier);
    expect(recordingStatus[0], PolarDataType.acc);

    await polar.stopOfflineRecording(identifier, PolarDataType.acc);

    final recordings = await polar.listOfflineRecordings(identifier);

    expect(recordings.length, 1);

    final entry = recordings.first;

    final accRecord = await polar.getOfflineAccRecord(identifier, entry);
    expect(accRecord?.data.samples.length, 1);

    final ppiRecord = await polar.getOfflineAccRecord(identifier, entry);
    expect(ppiRecord == null, true);

    final diskSpace = await polar.getDiskSpace(identifier);
    expect(diskSpace[1], 14362624);

    await polar.removeOfflineRecord(identifier, entry);

    final diskSpaceAfterRemove = await polar.getDiskSpace(identifier);
    expect(diskSpaceAfterRemove[1], 14369729);
  });
}
