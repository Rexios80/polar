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
  static const identifier = 'D7C70D2C';

  final polar = Polar();
  final logs = ['Service started'];

  PolarExerciseEntry? exerciseEntry;
  List<PolarOfflineRecordingEntry> recordings = [];
  bool isLoading = true;
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
              itemBuilder: (context) => RecordingAction.values
                  .map((e) => PopupMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onSelected: handleRecordingAction,
              child: const IconButton(
                icon: Icon(Icons.fiber_manual_record),
                disabledColor: Colors.white,
                onPressed: null,
              ),
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
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                log('listing offline recordings');
                fetchOfflineRecordings();
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
                                    identifier,
                                    recordings[index],
                                  );

                                  log('Fetched recording data: ${res.toString()}');
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => OfflineDataWidget(
                                        data: res,
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  title: Text(recordings[index].path),
                                  subtitle: Text(
                                    'Size: ${recordings[index].size} bytes, Date: ${recordings[index].date}, Type: ${recordings[index].type}',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
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

class OfflineDataWidget extends StatelessWidget {
  final PolarOfflineRecordingData data;
  const OfflineDataWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Offline data'),
      ),
      body: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Type: ${data.type}'),
                Text('Start time: ${data.startTime}'),
                if (data.settings != null) Text('Settings: ${data.settings}'),
                if (data.accData != null)
                  for (final acc in data.accData!.samples)
                    Text('Acc data: ${acc.x} ${acc.y} ${acc.z}'),
                if (data.gyroData != null)
                  for (final gyro in data.gyroData!.samples)
                    Text('Gyro data: ${gyro.x} ${gyro.y} ${gyro.z}'),
                if (data.magData != null)
                  for (final mag in data.magData!.samples)
                    Text('Mag data: ${mag.x} ${mag.y} ${mag.z}'),
                if (data.hrData != null)
                  for (final hr in data.hrData!.samples)
                    Text('Hr data: ${hr.hr}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
