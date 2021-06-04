# polar

Plugin wrapper for the Polar SDK

## Getting Started

### Android

app/build.gradle:

```
dependencies {
    implementation 'polarofficial:polar-ble-sdk:3.1.0@aar'
    implementation 'polarofficial:polar-protobuf-release:3.1.0@aar'
}
```

### iOS

Podfile:

```
platform :ios, '12.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'

      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
      ]
    end
  end
end
```

Info.plist:

```
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Used to connect to Polar devices</string>
```

## Use it

```
class MyClass with PolarApiObserver {
  void connect() {
    final polar = Polar(this);
    polar.connectToDevice('deviceId');
  }

  @override
  void batteryLevelReceived(String deviceId, int level) {
    // TODO
  }

  @override
  void blePowerStateChanged(bool state) {
    // TODO
  }

  @override
  void deviceConnected(PolarDeviceInfo info) {
    // TODO
  }

  @override
  void deviceConnecting(PolarDeviceInfo info) {
    // TODO
  }

  @override
  void deviceDisconnected(PolarDeviceInfo info) {
    // TODO
  }

  @override
  void disInformationReceived(String deviceId, String uuid, String info) {
    // TODO
  }

  @override
  void hrFeatureReady(String deviceId) {
    // TODO
  }

  @override
  void hrNotificationReceived(String deviceId, PolarHrData data) {
    // TODO
  }

  @override
  void polarFtpFeatureReady(String deviceId) {
    // TODO
  }

  @override
  void sdkModeFeatureAvailable(String deviceId) {
    // TODO
  }

  @override
  void streamingFeaturesReady(
      String deviceId, List<DeviceStreamingFeature> features) {
    // TODO
  }
}
```