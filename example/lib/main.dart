import 'package:flutter/material.dart';
import 'package:polar/polar.dart';

void main() {
  runApp(MyApp());
}

/// Example app
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const identifier = '1C709B20';

  late final Polar polar;
  List<String> logs = ['Service started'];

  @override
  void initState() {
    super.initState();

    polar = Polar();
    polar.heartRateStream.listen((e) => log('Heart rate: ${e.data.hr}'));
    polar.streamingFeaturesReadyStream.listen((e) {
      if (e.features.contains(DeviceStreamingFeature.ecg)) {
        polar
            .startEcgStreaming(e.identifier)
            .listen((e) => log('ECG data: ${e.samples}'));
      }
    });
    polar.deviceConnectingStream.listen((_) => log('Device connecting'));
    polar.deviceConnectedStream.listen((_) => log('Device connected'));
    polar.deviceDisconnectedStream.listen((_) => log('Device disconnected'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polar example app'),
          actions: [
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: () {
                log('Disconnecting from device: $identifier');
                polar.disconnectFromDevice(identifier);
              },
            ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                log('Connecting to device: $identifier');
                polar.connectToDevice(identifier);
              },
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.all(10),
          shrinkWrap: true,
          children: logs.reversed.map((e) => Text(e)).toList(),
        ),
      ),
    );
  }

  void log(String log) {
    print(log);
    setState(() {
      logs.add(log);
    });
  }
}
