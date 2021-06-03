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
  int battery = -1;
  int hr = -1;

  @override
  void initState() {
    super.initState();

    final polar = Polar();
    polar.batteryStream.listen((event) => setState(() => battery = event));
    polar.hrStream.listen((event) => setState(() => hr = event));
    polar.start('1C709B20');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polar example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Battery: $battery'),
              Text('Heart rate: $hr'),
            ],
          ),
        ),
      ),
    );
  }
}
