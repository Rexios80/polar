import 'package:flutter/material.dart';
import 'package:polar/polar.dart';

void main() {
  runApp(MyApp());
}

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
    polar
        .startEcgStreaming(identifier)
        .listen((e) => log('ECG data: ${e.samples}'));
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
              onPressed: () => polar.disconnectFromDevice(identifier),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () => polar.connectToDevice(identifier),
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
