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
  static const deviceId = '1C709B20';

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
              onPressed: () => polar.disconnectFromDevice(deviceId),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () => polar.connectToDevice(deviceId),
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
  void batteryLevelReceived(String deviceId, int level) {
    log('batteryLevelReceived: [$deviceId, $level]');
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
  void disInformationReceived(String deviceId, String uuid, String info) {
    log('disInformationReceived: [$deviceId, $uuid, $info]');
  }

  @override
  void hrFeatureReady(String deviceId) {
    log('hrFeatureReady: $deviceId');
  }

  @override
  void hrNotificationReceived(String deviceId, PolarHrData data) {
    log('hrNotificationReceived: [$deviceId, ${data.hr}]');
  }

  @override
  void polarFtpFeatureReady(String deviceId) {
    log('polarFtpFeatureReady: $deviceId');
  }

  @override
  void sdkModeFeatureAvailable(String deviceId) {
    log('sdkModeFeatureAvailable: $deviceId');
  }

  @override
  void streamingFeaturesReady(
      String deviceId, List<DeviceStreamingFeature> features) {
    log('streamingFeaturesReady: [$deviceId, $features]');
    if (features.contains(DeviceStreamingFeature.ecg)) {
      polar
        .startEcgStreaming(
          deviceId,
          PolarSensorSetting({}),
        )
        .listen((e) => log(e.samples.toString()));
    }
  }
}
