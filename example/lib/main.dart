import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

/// Example app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const identifier = 'D780C525'; // H10
  // static const identifier = 'AE0F8E27'; // Verity
  // static const identifier = 'E5C32C2E'; // Polar 360

  final polar = Polar();
  final logs = ['Service started'];

  PolarExerciseEntry? exerciseEntry;

  @override
  void initState() {
    super.initState();

    // polar
    //     .searchForDevice()
    //     .listen((e) => log('Found device in scan: ${e.deviceId}'));
    polar.batteryLevel.listen((e) => log('Battery: ${e.level}'));
    polar.deviceConnecting.listen((_) => log('Device connecting'));
    polar.deviceConnected.listen((_) => log('Device connected'));
    polar.deviceDisconnected.listen((_) => log('Device disconnected'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polar example app'),
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.fiber_manual_record),
              itemBuilder: (context) => RecordingAction.values
                  .map((e) => PopupMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onSelected: handleRecordingAction,
            ),
            PopupMenuButton(
              icon: const Icon(Icons.system_update),
              itemBuilder: (context) => FirmwareAction.values
                  .map((e) => PopupMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onSelected: handleFirmwareAction,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                log('Disconnecting from device: $identifier');
                polar.disconnectFromDevice(identifier);
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                log('Connecting to device: $identifier');
                polar.connectToDevice(identifier);
                streamWhenReady();
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(10),
          shrinkWrap: true,
          children: logs.reversed.map(Text.new).toList(),
        ),
      ),
    );
  }

  void streamWhenReady() async {
    await polar.sdkFeatureReady.firstWhere(
      (e) => e.identifier == identifier && e.feature == PolarSdkFeature.hr,
    );
    final availableHrTypes =
        await polar.getAvailableHrServiceDataTypes(identifier);
    debugPrint('available hr types: $availableHrTypes');

    if (availableHrTypes.contains(PolarDataType.hr)) {
      polar
          .startHrStreaming(identifier)
          .listen((e) => log('Heart rate: ${e.samples.map((e) => e.hr)}'));
    }

    await polar.sdkFeatureReady.firstWhere(
      (e) =>
          e.identifier == identifier &&
          e.feature == PolarSdkFeature.onlineStreaming,
    );
    final availableStreamTypes =
        await polar.getAvailableOnlineStreamDataTypes(identifier);
    debugPrint('available stream types: $availableStreamTypes');

    if (availableStreamTypes.contains(PolarDataType.ecg)) {
      polar
          .startEcgStreaming(identifier)
          .listen((e) => log('ECG data received'));
    }
    if (availableStreamTypes.contains(PolarDataType.acc)) {
      polar
          .startAccStreaming(identifier)
          .listen((e) => log('ACC data received'));
    }
  }

  void log(String log) {
    debugPrint(log);
    setState(() {
      logs.add(log);
    });
  }

  Future<void> handleRecordingAction(RecordingAction action) async {
    switch (action) {
      case RecordingAction.start:
        log('Starting recording');
        await polar.startRecording(
          identifier,
          exerciseId: const Uuid().v4(),
          interval: RecordingInterval.interval_1s,
          sampleType: SampleType.rr,
        );
        log('Started recording');
        break;
      case RecordingAction.stop:
        log('Stopping recording');
        await polar.stopRecording(identifier);
        log('Stopped recording');
        break;
      case RecordingAction.status:
        log('Getting recording status');
        final status = await polar.requestRecordingStatus(identifier);
        log('Recording status: $status');
        break;
      case RecordingAction.list:
        log('Listing recordings');
        final entries = await polar.listExercises(identifier);
        log('Recordings: $entries');
        // H10 can only store one recording at a time
        exerciseEntry = entries.first;
        break;
      case RecordingAction.fetch:
        log('Fetching recording');
        final exerciseEntry = this.exerciseEntry;
        if (exerciseEntry == null) {
          log('Exercises not yet listed');
          return;
        }
        final entry = await polar.fetchExercise(identifier, exerciseEntry);
        log('Fetched recording: $entry');
        break;
      case RecordingAction.remove:
        log('Removing recording');
        final exerciseEntry = this.exerciseEntry;
        if (exerciseEntry == null) {
          log('No exercise to remove. Try calling list first.');
          return;
        }
        await polar.removeExercise(identifier, exerciseEntry);
        log('Removed recording');
        break;
    }
  }

  Future<void> handleFirmwareAction(FirmwareAction action) async {
    switch (action) {
      case FirmwareAction.check:
        log('Checking firmware update');
        try {
          await for (final status in polar.checkFirmwareUpdate(identifier)) {
            log('Firmware check: $status');
          }
          log('Firmware check finished');
        } catch (e) {
          log('Firmware check failed: $e');
        }
        break;
      case FirmwareAction.update:
        log('Updating firmware (this erases device data)');
        try {
          await for (final status in polar.updateFirmware(identifier)) {
            log('Firmware update: $status');
          }
          log('Firmware update finished');
        } catch (e) {
          log('Firmware update failed: $e');
        }
        break;
    }
  }
}

enum RecordingAction {
  start,
  stop,
  status,
  list,
  fetch,
  remove,
}

enum FirmwareAction {
  check,
  update,
}
