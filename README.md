# polar

Plugin wrapper for the [Polar SDK](https://github.com/polarofficial/polar-ble-sdk)

## Note

This is an unofficial wrapper for the Polar SDK. For any questions regarding the underlying SDKs or Polar devices in general, please see the [official repository](https://github.com/polarofficial/polar-ble-sdk).

## Getting Started

### Android

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

## Usage

<!-- embedme readme/usage.dart -->
```dart
import 'package:flutter/foundation.dart';
import 'package:polar/polar.dart';

const identifier = '1C709B20';
final polar = Polar();

void example() {
  polar.heartRateStream.listen((e) => debugPrint('Heart rate: ${e.data.hr}'));
  polar.streamingFeaturesReadyStream.listen((e) {
    if (e.features.contains(DeviceStreamingFeature.ecg)) {
      polar
          .startEcgStreaming(e.identifier)
          .listen((e) => debugPrint('ECG data: ${e.samples}'));
    }
  });
  polar.connectToDevice(identifier);
}

```