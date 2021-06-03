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
  int battery = -1;
  int hr = -1;

  @override
  void initState() {
    super.initState();

    final polar = Polar(this);
    polar.connectToDevice('1C709B20');
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

  @override
  void batteryLevelReceived(String deviceId, int level) {
    // TODO: implement batteryLevelReceived
  }

  @override
  void blePowerStateChanged(bool state) {
    // TODO: implement blePowerStateChanged
  }

  @override
  void deviceConnected(PolarDeviceInfo info) {
    // TODO: implement deviceConnected
  }

  @override
  void deviceConnecting(PolarDeviceInfo info) {
    // TODO: implement deviceConnecting
  }

  @override
  void deviceDisconnected(PolarDeviceInfo info) {
    // TODO: implement deviceDisconnected
  }

  @override
  void disInformationReceived(String deviceId, String uuid, String info) {
    // TODO: implement disInformationReceived
  }

  @override
  void hrFeatureReady(String deviceId) {
    // TODO: implement hrFeatureReady
  }

  @override
  void hrNotificationReceived(String deviceId, PolarHrData data) {
    // TODO: implement hrNotificationReceived
  }

  @override
  void polarFtpFeatureReady(String deviceId) {
    // TODO: implement polarFtpFeatureReady
  }

  @override
  void sdkModeFeatureAvailable(String deviceId) {
    // TODO: implement sdkModeFeatureAvailable
  }

  @override
  void streamingFeaturesReady(
      String deviceId, List<DeviceStreamingFeature> features) {
    // TODO: implement streamingFeaturesReady
  }
}
