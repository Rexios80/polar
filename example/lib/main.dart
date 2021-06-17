import 'package:flutter/material.dart';
import 'package:polar/polar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with PolarApiObserver {
  static const identifier = '1C709B20';

  late final Polar polar;
  List<String> logs = ['Service started'];

  @override
  void initState() {
    super.initState();

    polar = Polar(this);
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

  @override
  void batteryLevelReceived(String identifier, int level) {
    log('batteryLevelReceived: [$identifier, $level]');
  }

  @override
  void blePowerStateChanged(bool state) {
    log('blePowerStateChanged: $state');
  }

  @override
  void deviceConnected(PolarDeviceInfo info) {
    log('deviceConnected: ${info.deviceId}');
  }

  @override
  void deviceConnecting(PolarDeviceInfo info) {
    log('deviceConnecting: ${info.deviceId}');
  }

  @override
  void deviceDisconnected(PolarDeviceInfo info) {
    log('deviceDisconnected: ${info.deviceId}');
  }

  @override
  void disInformationReceived(String identifier, String uuid, String info) {
    log('disInformationReceived: [$identifier, $uuid, $info]');
  }

  @override
  void hrFeatureReady(String identifier) {
    log('hrFeatureReady: $identifier');
  }

  @override
  void hrNotificationReceived(String identifier, PolarHrData data) {
    log('hrNotificationReceived: [$identifier, ${data.hr}]');
  }

  @override
  void polarFtpFeatureReady(String identifier) {
    log('polarFtpFeatureReady: $identifier');
  }

  @override
  void sdkModeFeatureAvailable(String identifier) {
    log('sdkModeFeatureAvailable: $identifier');
  }

  @override
  void streamingFeaturesReady(
      String identifier, List<DeviceStreamingFeature> features) async {
    log('streamingFeaturesReady: [$identifier, $features]');
    if (features.contains(DeviceStreamingFeature.ecg)) {
      polar
          .startEcgStreaming(identifier)
          .listen((e) => log('ECG data: ${e.samples}'));
    }
    if (features.contains(DeviceStreamingFeature.acc)) {
      polar.startAccStreaming(identifier).listen((e) {
        log('ACC data: ${e.samples}');
      });
    }
    if (features.contains(DeviceStreamingFeature.gyro)) {
      polar
          .startGyroStreaming(identifier)
          .listen((e) => log('Gyro data: ${e.samples}'));
    }
    if (features.contains(DeviceStreamingFeature.magnetometer)) {
      polar
          .startMagnetometerStreaming(identifier)
          .listen((e) => log('Magnetometer data: ${e.samples}'));
    }
    if (features.contains(DeviceStreamingFeature.ppg)) {
      polar
          .startOhrStreaming(identifier)
          .listen((e) => log('PPG data: ${e.samples}'));
    }
    if (features.contains(DeviceStreamingFeature.ppi)) {
      polar
          .startOhrPPIStreaming(identifier)
          .listen((e) => log('PPI data: ${e.samples}'));
    }
  }
}
