import 'dart:async';

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

void testBasicData(
  String identifier, {
  PolarChargeState expectedChargeState = PolarChargeState.unknown,
}) {
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

    test('batteryChargingStatus', () async {
      final chargeState = await polar.batteryChargingStatus.first;
      expect(chargeState.chargingStatus, expectedChargeState);
    });
  });
}

void testBleSdkFeatures(
  String identifier, {
  required Set<PolarSdkFeature> features,
}) {
  test('Ble sdk features', () async {
    await connect(identifier);

    final available = <PolarSdkFeature>{};
    final sub = polar.sdkFeatureReady.listen((e) => available.add(e.feature));
    await Future.delayed(const Duration(seconds: 3));
    unawaited(sub.cancel());

    expect(setEquals(available, features), true);
    await disconnect(identifier);
  });
}

void testHrService(String identifier) {
  test('hr service', () async {
    await connect(identifier);
    await polar.sdkFeatureReady.firstWhere(
      (e) => e.feature == PolarSdkFeature.hr,
    );
    final available = await polar.getAvailableHrServiceDataTypes(identifier);
    expect(setEquals(available, {PolarDataType.hr}), true);
    await disconnect(identifier);
  });
}

void testStreaming(String identifier, {required Set<PolarDataType> features}) {
  group('streaming', () {
    setUpAll(() async {
      await connect(identifier);
      await polar.sdkFeatureReady.firstWhere(
        (e) => e.feature == PolarSdkFeature.onlineStreaming,
      );
      final available = await polar.getAvailableOnlineStreamDataTypes(
        identifier,
      );
      expect(setEquals(available, features), true);
    });

    tearDownAll(() async {
      await disconnect(identifier);
    });

    test('hr', () async {
      final hrData = await polar.startHrStreaming(identifier).first;
      expect(hrData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.hr));

    test('ecg', () async {
      final ecgData = await polar.startEcgStreaming(identifier).first;
      expect(ecgData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.ecg));

    test('acc', () async {
      final accData = await polar.startAccStreaming(identifier).first;
      expect(accData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.acc));

    test('ppg', () async {
      final ppgData = await polar.startPpgStreaming(identifier).first;
      expect(ppgData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.ppg));

    test('gyro', () async {
      final gyroData = await polar.startGyroStreaming(identifier).first;
      expect(gyroData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.gyro));

    test('magnetometer', () async {
      final magnetometerData = await polar
          .startMagnetometerStreaming(identifier)
          .first;
      expect(magnetometerData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.magnetometer));

    test('ppi', () async {
      final ppiData = await polar.startPpiStreaming(identifier).first;
      expect(ppiData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.ppi));

    test('skin-temperature', () async {
      final temperatureData = await polar
          .startSkinTemperatureStreaming(identifier)
          .first;
      expect(temperatureData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.skinTemperature));

    test('pressure', () async {
      final pressureData = await polar.startPressureStreaming(identifier).first;
      expect(pressureData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.pressure));

    test('location', () async {
      final locationData = await polar.startLocationStreaming(identifier).first;
      expect(locationData.samples.length, greaterThan(0));
    }, skip: !features.contains(PolarDataType.location));
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

    await polar.sdkFeatureReady.firstWhere(
      (e) => e.feature == PolarSdkFeature.sdkMode,
    );

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

void testMisc(String identifier, {required bool supportsLedConfig}) {
  test('misc', () async {
    await connect(identifier);
    // Wait to ensure device is connected (not sure why this is necessary)
    await Future.delayed(const Duration(seconds: 3));
    if (supportsLedConfig) {
      await polar.setLedConfig(
        identifier,
        const LedConfig(ppiModeLedEnabled: false, sdkModeLedEnabled: false),
      );
      await polar.setLedConfig(
        identifier,
        const LedConfig(ppiModeLedEnabled: true, sdkModeLedEnabled: true),
      );
    }

    await polar.doFactoryReset(identifier, false);
    await disconnect(identifier);
  });
}

void testFtu(String identifier) {
  test('ftu', () async {
    await connect(identifier);
    final config = PolarFirstTimeUseConfig(
      gender: FtuGender.male,
      birthDate: DateTime(1990, 1, 1),
      height: 177,
      weight: 77,
      maxHeartRate: 220 - 35,
      vo2Max: 40,
      restingHeartRate: 60,
      trainingBackground: FtuTrainingBackground.occasional,
      sleepGoalMinutes: 480,
      typicalDay: FtuTypicalDay.mostlySitting,
      deviceTime: DateTime.timestamp(),
    );

    await polar.doFirstTimeUse(identifier, config);
    final status = await polar.isFtuDone(identifier);
    expect(status, true);

    await disconnect(identifier);
  });
}

void test247HrSamples(String identifier) {
  group('24/7 HR samples', () {
    setUp(() async {
      await connect(identifier);
    });

    tearDown(() async {
      await disconnect(identifier);
    });

    test('get samples for single day', () async {
      final today = DateTime.timestamp();
      final todayDate = DateTime(today.year, today.month, today.day);

      final result = await polar.get247HrSamples(
        identifier,
        todayDate,
        todayDate,
      );

      expect(result.length, 1);
      expect(result.first.date.year, todayDate.year);
      expect(result.first.date.month, todayDate.month);
      expect(result.first.date.day, todayDate.day);
      expect(result.first.samples.isNotEmpty, true);
    });

    test('get samples for multiple days', () async {
      final today = DateTime.timestamp();
      final todayDate = DateTime(today.year, today.month, today.day);
      final threeDaysAgo = todayDate.subtract(const Duration(days: 3));

      final result = await polar.get247HrSamples(
        identifier,
        threeDaysAgo,
        todayDate,
      );

      // Should return 4 days of data (inclusive)
      expect(result.length, 4);

      // Verify dates are in the correct range
      for (final data in result) {
        expect(
          data.date.isAfter(threeDaysAgo.subtract(const Duration(days: 1))),
          true,
        );
        expect(
          data.date.isBefore(todayDate.add(const Duration(days: 1))),
          true,
        );
      }
    });

    test('verify sample data structure', () async {
      final today = DateTime.timestamp();
      final todayDate = DateTime(today.year, today.month, today.day);

      final result = await polar.get247HrSamples(
        identifier,
        todayDate,
        todayDate,
      );

      expect(result.isNotEmpty, true);

      final firstDay = result.first;
      expect(firstDay.samples.isNotEmpty, true);

      // Verify sample group structure
      for (final sampleGroup in firstDay.samples) {
        expect(sampleGroup.startTime.isNotEmpty, true);
        expect(sampleGroup.hrSamples.isNotEmpty, true);
        expect(sampleGroup.triggerType.isNotEmpty, true);

        // Verify each HR value is within reasonable range
        for (final hr in sampleGroup.hrSamples) {
          expect(hr, greaterThan(0));
          expect(hr, lessThan(300)); // Sanity check for HR value
        }
      }
    });

    test('verify trigger types', () async {
      final today = DateTime.timestamp();
      final todayDate = DateTime(today.year, today.month, today.day);

      final result = await polar.get247HrSamples(
        identifier,
        todayDate,
        todayDate,
      );

      expect(result.isNotEmpty, true);

      // Check that trigger types are present in the data
      final allSampleGroups = result.expand((day) => day.samples).toList();
      final triggerTypes = allSampleGroups.map((s) => s.triggerType).toSet();

      // Should have at least one trigger type
      expect(triggerTypes.length, greaterThan(0));
    });

    test('date range ordering', () async {
      final today = DateTime.timestamp();
      final todayDate = DateTime(today.year, today.month, today.day);
      final weekAgo = todayDate.subtract(const Duration(days: 7));

      final result = await polar.get247HrSamples(
        identifier,
        weekAgo,
        todayDate,
      );

      // Verify results are ordered by date
      for (var i = 0; i < result.length - 1; i++) {
        expect(
          result[i].date.isBefore(result[i + 1].date) ||
              result[i].date.isAtSameMomentAs(result[i + 1].date),
          true,
          reason: 'Dates should be in chronological order',
        );
      }
    });

    test('samples within day are ordered', () async {
      final today = DateTime.timestamp();
      final todayDate = DateTime(today.year, today.month, today.day);

      final result = await polar.get247HrSamples(
        identifier,
        todayDate,
        todayDate,
      );

      expect(result.isNotEmpty, true);

      // Check that data structure is valid
      for (final dayData in result) {
        expect(dayData.samples.isNotEmpty, true);
        // Check that each sample group has valid data
        for (final sampleGroup in dayData.samples) {
          expect(sampleGroup.startTime.isNotEmpty, true);
          expect(sampleGroup.hrSamples.isNotEmpty, true);
        }
      }
    });
  });
}
