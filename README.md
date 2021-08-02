# polar

Plugin wrapper for the Polar SDK

## Getting Started

### Android

app/build.gradle:

```
dependencies {
    implementation 'polarofficial:polar-ble-sdk:3.2.0@aar'
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
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Used to connect to Polar devices</string>
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>
```

## Use it

```
polar = Polar();
polar.heartRateStream.listen((e) => print('Heart rate: ${e.data.hr}'));
polar.streamingFeaturesReadyStream.listen((e) {
  if (e.features.contains(DeviceStreamingFeature.ecg)) {
    polar
        .startEcgStreaming(e.identifier)
        .listen((e) => print('ECG data: ${e.samples}'));
  }
});
```