## 7.7.2

- Fixes issue with sample data deserialization (by [@thpir](https://github.com/thpir) in [#64](https://github.com/Rexios80/polar/pull/64))

## 7.7.1

- Upgrades `device_info_plus` to `12.0.0` (by [@iarata](https://github.com/iarata) in [#63](https://github.com/Rexios80/polar/pull/63))

## 7.7.0

- Upgrades Polar SDK to `6.3.0`
- Adds support for `getAvailableHRServiceDataTypes`

## 7.6.1

- Dependency upgrades

## 7.6.0

- Converts native method invocations to `EventChannel` to fix background callback issues
- Upgrades Polar SDK to `6.1.1` (by [@HaveANiceDay33](https://github.com/HaveANiceDay33) in [#52](https://github.com/Rexios80/polar/pull/52))

## 7.5.1

- Dependency upgrades

## 7.5.0

- Fixes temperature and pressure decoding on iOS
- Specifies `jvmTarget` to fix Android build issues
- Initializes Android SDK on method call instead of on plugin registration
- Invokes iOS methods on the main queue
- Fixes `PolarSensorSetting` deserialization

## 7.4.0

- Updates Polar SDK to `5.7.0`
- Adds support for temperature and pressure streaming
- Maybe fixes issues with multiple Flutter engine instances on Android

## 7.3.0

- Discard subsequent `onAttachedToEngine` calls on Android

## 7.2.0

- Dependency upgrades

## 7.1.0

- Adds support for SDK mode

## 7.0.0

- Upgrades Polar SDK to `5.5.0`
- BREAKING: Replaces `enableLedAnimation` with `setLedConfig`
- BREAKING: Requires dart `^3.0.0`

## 6.2.0

- Upgrades Polar SDK to `5.4.0`
- Adds `doFactoryReset` method

## 6.1.1

- Upgrades permission_handler to version 11.0.0

## 6.1.0

- Updates Polar SDK to `5.3.0`
- Adds support for `enableLedAnimation` call

## 6.0.1

- Updates for Flutter 3.13.0

## 6.0.0

- Updates Polar SDK to `5.2.0`
- BREAKING: `deviceDisconencted` stream now outputs `PolarDeviceDisconnectedEvent`

## 5.2.1

- Adds namespace to `build.gradle` to support Gradle 8

## 5.2.0

- Dependency upgrades

## 5.1.0

- Updates Polar SDK to `5.1.0`

## 5.0.0

- Updates Polar SDK to `5.0.0`
- BREAKING
  - Minimum iOS version is now `14.0`
  - All sample timestamps are now converted to `DateTime`
- Renames
  - `PolarOhrPpiSample` -> `PolarPpiSample`
  - `PolarOhrPpiData` -> `PolarPpiData`
  - `startOhrStreaming` -> `startPpgStreaming`
  - `startOhrPpiStreaming` -> `startPpiStreaming`
  - `DeviceStreamingFeature` -> `PolarDataType`
  - `streamingFeaturesReady` -> `sdkFeatureReady`
  - Removes `Stream` suffix from all stream fields
- Removals
  - The following are now handled with `sdkFeatureReady`
    - `ftpFeatureReady`
    - `hrFeatureReady`
    - `sdkModeFeatureAvailable`
  - `hrNotificationReceived` functionality has been moved to streaming
  - `PolarHrData.rrs` has been removed in favor of `PolarHrData.rrsMs`
- See [the migration guide](https://github.com/polarofficial/polar-ble-sdk/blob/polar-ble-sdk-5.0.0/documentation/MigrationGuide5.0.0.md) and example for more details

## 4.1.0

- The `Polar` initializer now returns a singleton

## 4.0.0

- Updates Polar SDK to 4.0.0
- Other version updates

## 4.0.0-beta0

- Updates Polar SDK to 4.0.0-beta0
- BREAKING: Moves `timeStamp` field from streaming data into individual samples
- BREAKING: Renames `startOhrPPIStreaming` to `startOhrPpiStreaming`
- BREAKING: `PolarEcgData`, `PolarAccData`, `PolarGyroData`, `PolarMagnetometerData`, `PolarOhrData`, `PolarOhrPpiData`, and `PolarExerciseData`, no longer contain `identifier` fields
- BREAKING: Removes `DeviceStreamingFeature.error`
- BREAKING: `PolarSensorSetting` now properly conforms to the SDK equivalent. Attempting to start streaming with improperly formatted settings will now throw an assertion error.
- Adds integration tests
- Uses `json_serializable` for internal serialization instead of manual serialization

## 3.7.0

- Fixes issue with PPI streaming

## 3.6.0

- Dynamically register streaming channels

## 3.5.0

- Fixes issues with EventChannels
- Better error reporting to Flutter from Android
- Fixes `ftpFeatureReady` method string mismatch
- Upgrades Android Gradle Plugin

## 3.4.1

- Fixes formatting

## 3.4.0

- Upgrades dependencies
- Adds `toString` override for `Xyz` class

## 3.3.0

- Upgrades dependencies

## 3.2.0

- Adds recording features
- Adds `scanForDevice`
- Refactors streaming to use `EventChannel`s internally
- `disconnectFromDevice` now returns a `Future`
- Updated Polar SDK to 3.3.6 (fixes `streamingFeaturesReady` not being called)

## 3.1.0

- Updated Polar SDK to 3.3.4

## 3.0.0

- Android minimum SDK is lifted from 21 to 24
- Updated Polar SDK to 3.3.3

## 2.2.0

- `connectToDevice` now returns a future
- Requesting permissions in `connectToDevice` is now optional

## 2.1.0

- Fixes issues deserializing `OhrDataType` and `PolarOhrPpiSample`

## 2.0.0

- BREAKING CHANGE: Updated Android compileSdkVersion to 33 for `permission_handler`
- Updated dependencies

## 1.17.0

- Updated Polar SDK to 3.3.2

## 1.16.0

- Updated Polar SDK to 3.3.1

## 1.15.0

- Updated Polar SDK to 3.2.10

## 1.14.0

- Updated Polar SDK to 3.2.9

## 1.13.0

- Updated Polar SDK to 3.2.8

## 1.12.0

- No longer requests bluetooth permission on app startup on iOS

## 1.11.0

- Fixed crash on Android when detaching from engine

## 1.10.0

- Fixed lifecycle issues on Android

## 1.9.0

- Updated Polar SDK to 3.2.7
- Updated documentation

## 1.8.1

- Fixed typo

## 1.8.0

- Fixed dangling native method calls
- Changes to android/app/build.gradle are no longer required

## 1.7.0

- Specify version constraint for Polar SDK on iOS

## 1.6.0

- Updated Polar SDK
- Minimum iOS deployment target is now 13
- Changes to post_install section of Podfile are no longer required
- Request the required permissions on Android S+
- Fixed battery level not being received on iOS

## 1.5.0

- Fixed conflict with location permissions
- Updated documentation

## 1.4.0

- Fixed ProGuard issues. Disabling minify is no longer required.

## 1.3.0

- Updated analysis options
- Updated Polar SDK
- Removed EnumToString dependency

## 1.2.0

- Restructured the package to use exports
- Updated Polar SDK

## 1.1.1

- Updated Polar SDK and readme for Android

## 1.1.0

- Updated Polar SDK

## 1.0.1

- Fixed changelog formatting

## 1.0.0

- Copied documentation from the iOS PolarBleSdk

## 0.2.3

- Fixed an issue PPI streaming

## 0.2.2

- Fixed a crash that could happen on iOS

## 0.2.1

- Filter streaming data by identifier to match the native API

## 0.2.0

- Added streaming features and made the API more user friendly

## 0.1.6

- Give me my Pub points

## 0.1.5

- Added bluetooth background mode for iOS

## 0.1.4

- Removed unnecessary location permission on iOS

## 0.1.3

- Updated changelog

## 0.1.2

- Updated readme

## 0.1.1

- Updated readme

## 0.1.0

- Wrap more API features

## 0.0.1

- Initial release
