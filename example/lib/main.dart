import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:polar_example/oflline_data_widget.dart';
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
  static const identifier = 'D7C72E23';

  final polar = Polar();
  final logs = ['Service started'];

  PolarExerciseEntry? exerciseEntry;
  List<PolarOfflineRecordingEntry> recordings = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();

    // polar.batteryLevel.listen((e) => log('Battery: ${e.level}'));

    polar.deviceConnecting.listen((_) => log('Device connecting'));
    polar.deviceConnected.listen((_) => log('Device connected'));
    polar.deviceDisconnected.listen((_) => log('Device disconnected'));
  }

  Future<void> fetchOfflineRecordings() async {
    try {
      final fetchedRecordings = await polar.listOfflineRecordings(identifier);
      setState(() {
        recordings = fetchedRecordings;
        isLoading = false;
      });
    } catch (e) {
      log('Failed to fetch recordings: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polar example app'),
          actions: [
            ElevatedButton(
              onPressed: setOfflineRecordingTrigger,
              child: const Text('Set Offline Recording Trigger'),
            ),
            ElevatedButton(
              onPressed: () {
                log('Enabling SDK mode for device: $identifier');
                polar.enableSdkMode(identifier).then((value) {
                  log('Device Sdk mode enabled');
                });
              },
              child: const Text('Enable SDK mode'),
            ),
            ElevatedButton(
              onPressed: () {
                log('Disabling SDK mode for device: $identifier');
                polar.disableSdkMode(identifier).then((value) {
                  log('Device Sdk mode disabled');
                });
              },
              child: const Text('Disable SDK mode'),
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
                // streamWhenReady();
                //if device is connected, enable sdk mode
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Logs:'),
              SizedBox(
                height: MediaQuery.of(context).size.height / 2 - 100,
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  shrinkWrap: true,
                  children: logs.reversed.map(Text.new).toList(),
                ),
              ),
              TextButton(
                onPressed: () =>
                    handleRecordingAction(RecordingAction.settings),
                child: const Text('Start offline recording'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () =>
                        handleRecordingAction(RecordingAction.offlineStop),
                    child: const Text('Stop recording'),
                  ),
                  TextButton(
                    onPressed: () =>
                        handleRecordingAction(RecordingAction.ofllineList),
                    child: const Text('Listing offline recordings'),
                  ),
                ],
              ),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : recordings.isEmpty
                      ? const Center(child: Text('No recordings found'))
                      : SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: ListView.builder(
                            itemCount: recordings.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                  onTap: () async {
                                    final res = await polar.fetchOfflineRecording(
                                        identifier, recordings[index],);

                                    log('Fetched recording data: ${res.toString()}');
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                OfflineDataWidget(
                                                  data: res,
                                                ),),);
                                  },
                                  child: ListTile(
                                    title: Text(recordings[index].path),
                                    subtitle: Text(
                                        'Size: ${recordings[index].size} bytes, Date: ${recordings[index].date}, Type: ${recordings[index].type}',),
                                  ),);
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> setOfflineRecordingTrigger() async {
    await polar.setOfflineRecordingTrigger(
      identifier,
    );
  }

  void streamWhenReady() async {
    await polar.sdkFeatureReady.firstWhere(
      (e) =>
          e.identifier == identifier &&
          e.feature == PolarSdkFeature.onlineStreaming,
    );
    final availabletypes =
        await polar.getAvailableOnlineStreamDataTypes(identifier);

    debugPrint('available types: $availabletypes');

    if (availabletypes.contains(PolarDataType.hr)) {
      polar
          .startHrStreaming(identifier)
          .listen((e) => log('Heart rate: ${e.samples.map((e) => e.hr)}'));
    }
    if (availabletypes.contains(PolarDataType.ecg)) {
      polar
          .startEcgStreaming(identifier)
          .listen((e) => log('ECG data received'));
    }
    if (availabletypes.contains(PolarDataType.acc)) {
      polar
          .startAccStreaming(identifier)
          .listen((e) => log('ACC data received'));
    }
  }

  void log(String log) {
    // ignore: avoid_print
    print(log);
    setState(() {
      logs.add(log);
    });
  }

  String formatPolarSensorSetting(PolarSensorSetting settings) {
    final buffer = StringBuffer();

    settings.settings.forEach((key, value) {
      buffer.writeln('${key.toString().split('.').last}: ${value.join(', ')}');
    });

    return buffer.toString();
  }

  Future<void> handleRecordingAction(RecordingAction action) async {
    switch (action) {
      case RecordingAction.start:
        log('Starting recording');
        await polar.startRecording(
          identifier,
          exerciseId: const Uuid().v4(),
          interval: RecordingInterval.interval_1s,
          sampleType: SampleType.hr,
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
        if (exerciseEntry == null) {
          log('Exercises not yet listed');
          await handleRecordingAction(RecordingAction.list);
        }
        final entry = await polar.fetchExercise(identifier, exerciseEntry!);
        log('Fetched recording: $entry');
        break;
      case RecordingAction.remove:
        log('Removing recording');
        if (exerciseEntry == null) {
          log('No exercise to remove. Try calling list first.');
          return;
        }
        await polar.removeExercise(identifier, exerciseEntry!);
        log('Removed recording');
        break;
      case RecordingAction.settings:
        log('Getting recording settings');
        final settings = await polar.requestOfflineRecordingSettings(
          identifier,
          PolarDataType.acc,
        );
        log('Recording settings: ${formatPolarSensorSetting(settings)}');
        break;

      case RecordingAction.offlineStart:
        log('Starting offline recording');
        try {
          final res = await polar.requestRecordingStatus(identifier);

          log('Recording status: ${res.toString()}');
          // await polar.startOfflineRecording(
          //   identifier,
          //   PolarDataType.hr,
          // );
          log('Started offline recording');
        } catch (e) {
          log('Error starting offline recording: $e');
        }

        break;

      case RecordingAction.offlineStop:
        log('Stopping offline recording');
        try {
          await polar.stopOfflineRecording(identifier, PolarDataType.acc);
          await polar.stopOfflineRecording(identifier, PolarDataType.hr);
          await polar.stopOfflineRecording(identifier, PolarDataType.gyro);
          // await polar.stopOfflineRecording(
          //     identifier, PolarDataType.magnetometer);
          log('Stopped offline recording');
        } catch (e) {
          log('Error stopping offline recording: $e');
        }
        break;

      case RecordingAction.ofllineList:
        log('Listing offline recordings');
        await fetchOfflineRecordings();

        break;
    }
  }
}

enum RecordingAction {
  offlineStart,
  offlineStop,
  ofllineList,
  start,
  stop,
  status,
  list,
  fetch,
  remove,
  settings,
}
