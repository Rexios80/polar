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
    final connecting = polar.deviceConnecting.firstWhere(
      (e) => e.deviceId == identifier,
    );
    final connected = polar.deviceConnected.firstWhere(
      (e) => e.deviceId == identifier,
    );

    await polar.connectToDevice(identifier);

    expect((await connecting).deviceId, identifier);
    expect((await connected).deviceId, identifier);

    final disconnected = polar.deviceDisconnected.firstWhere(
      (e) => e.info.deviceId == identifier,
    );
    await polar.disconnectFromDevice(identifier);
    expect((await disconnected).info.deviceId, identifier);
  });
}

/// Ensure device connects
Future<PolarSdkFeaturesReadinessEvent> connect(String identifier) async {
  final readiness = polar.sdkFeaturesReadiness.firstWhere(
    (e) => e.identifier == identifier,
  );
  await polar.connectToDevice(identifier);
  return readiness;
}

/// Ensure device disconnects
Future<void> disconnect(String identifier) async {
  final disconnected = polar.deviceDisconnected.firstWhere(
    (e) => e.info.deviceId == identifier,
  );
  await polar.disconnectFromDevice(identifier);
  await disconnected;
}

void testBasicData(
  String identifier, {
  PolarChargeState expectedChargeState = PolarChargeState.unknown,
}) {
  group('basic data', () {
    late PolarDisInformationEvent disInformation;
    late PolarBatteryLevelEvent batteryEvent;
    late PolarBatteryChargingStatusEvent chargeState;

    setUpAll(() async {
      final dis = polar.disInformation.firstWhere(
        (e) => e.identifier == identifier,
      );
      final battery = polar.batteryLevel.firstWhere(
        (e) => e.identifier == identifier,
      );
      final charge = polar.batteryChargingStatus.firstWhere(
        (e) => e.identifier == identifier,
      );

      await connect(identifier);
      disInformation = await dis;
      batteryEvent = await battery;
      chargeState = await charge;
    });

    tearDownAll(() async {
      await disconnect(identifier);
    });

    test('disInformation', () {
      expect(disInformation.identifier, identifier);
    });

    test('batteryLevel', () {
      expect(batteryEvent.level, greaterThan(0));
    });

    test('batteryChargingStatus', () {
      expect(chargeState.chargingStatus, expectedChargeState);
    });
  });
}

void testBleSdkFeatures(
  String identifier, {
  required Set<PolarSdkFeature> features,
}) {
  test('ble sdk features', () async {
    final readyFeatures = <PolarSdkFeature>{};
    final sub = polar.sdkFeatureReady
        .where((e) => e.identifier == identifier)
        .listen((e) => readyFeatures.add(e.feature));

    final readiness = await connect(identifier);
    expect(readiness.ready, unorderedEquals(features));
    expect(
      readiness.unavailable,
      unorderedEquals(PolarSdkFeature.values.toSet().difference(features)),
    );
    expect(readyFeatures, containsAll(readiness.ready));

    await sub.cancel();
    await disconnect(identifier);
  });
}

void testHrService(String identifier) {
  test('hr service', () async {
    await connect(identifier);
    final available = await polar.getAvailableHrServiceDataTypes(identifier);
    expect(available, unorderedEquals({PolarDataType.hr}));
    await disconnect(identifier);
  });
}

void testStreaming(String identifier, {required Set<PolarDataType> features}) {
  group('streaming', () {
    setUpAll(() async {
      await connect(identifier);
      final available = await polar.getAvailableOnlineStreamDataTypes(
        identifier,
      );
      expect(available, unorderedEquals(features));
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
      // RR samples only exist after some recording time; there is no ready event
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

void testMisc(String identifier, {required bool supportsLedConfig}) {
  test('misc', () async {
    await connect(identifier);
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

void testShutDown(String identifier) {
  test('shutDown', () async {
    await connect(identifier);
    await polar.shutDown();
    await connect(identifier);
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
