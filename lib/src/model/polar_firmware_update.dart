import 'package:meta/meta.dart';

/// Result of [Polar.checkFirmwareUpdate]
enum PolarCheckFirmwareUpdateKind {
  /// A newer firmware version is available
  checkFwUpdateAvailable,

  /// The device is already on the latest firmware
  checkFwUpdateNotAvailable,

  /// The firmware update check failed
  checkFwUpdateFailed,
}

/// Status emitted by [Polar.checkFirmwareUpdate]
@immutable
class PolarCheckFirmwareUpdateStatus {
  /// The check result
  final PolarCheckFirmwareUpdateKind kind;

  /// Available version when [kind] is
  /// [PolarCheckFirmwareUpdateKind.checkFwUpdateAvailable], otherwise details
  /// from the native SDK
  final String details;

  /// Constructor
  const PolarCheckFirmwareUpdateStatus({
    required this.kind,
    required this.details,
  });

  /// From native JSON
  factory PolarCheckFirmwareUpdateStatus.fromJson(Map<String, dynamic> json) {
    return PolarCheckFirmwareUpdateStatus(
      kind: PolarCheckFirmwareUpdateKind.values.byName(json['kind'] as String),
      details: json['details'] as String,
    );
  }

  /// To native JSON
  Map<String, dynamic> toJson() => {'kind': kind.name, 'details': details};

  @override
  String toString() => '$kind($details)';
}

/// Progress of [Polar.updateFirmware]
enum PolarFirmwareUpdateKind {
  /// Downloading the firmware package
  fetchingFwUpdatePackage,

  /// Preparing the device (backup / factory reset / reconnect)
  preparingDeviceForFwUpdate,

  /// Writing firmware files to the device
  writingFwUpdatePackage,

  /// Rebooting and reconnecting after the write
  finalizingFwUpdate,

  /// Firmware update completed successfully
  fwUpdateCompletedSuccessfully,

  /// No firmware update is available
  fwUpdateNotAvailable,

  /// Firmware update failed
  fwUpdateFailed,
}

/// Status emitted by [Polar.updateFirmware]
@immutable
class PolarFirmwareUpdateStatus {
  /// The update stage
  final PolarFirmwareUpdateKind kind;

  /// Human-readable progress or error details from the native SDK
  final String details;

  /// Constructor
  const PolarFirmwareUpdateStatus({required this.kind, required this.details});

  /// From native JSON
  factory PolarFirmwareUpdateStatus.fromJson(Map<String, dynamic> json) {
    return PolarFirmwareUpdateStatus(
      kind: PolarFirmwareUpdateKind.values.byName(json['kind'] as String),
      details: json['details'] as String,
    );
  }

  /// To native JSON
  Map<String, dynamic> toJson() => {'kind': kind.name, 'details': details};

  @override
  String toString() => '$kind($details)';
}
