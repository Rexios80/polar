# polar

Plugin wrapper for the Polar SDK

## Getting Started

### Android

app/build.gradle:

```groovy
dependencies {
    implementation 'polarofficial:polar-ble-sdk:3.2.6@aar'
}
```

android/app/src/main/AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="30" />
```

If you use `BLUETOOTH_SCAN` to determine location, remove `android:usesPermissionFlags="neverForLocation"`

If you use location services in your app, remove `android:maxSdkVersion="30"` from the location permission tags

### iOS

Change the deployment target in Xcode to iOS 13+

Podfile:

```ruby
platform :ios, '13.0'
```

Info.plist:

```xml
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

```dart
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