import 'dart:io';

/// represents the charge state of a Polar device
enum PolarChargeState {
  /// unknown
  unknown,

  /// charging
  charging,

  /// not charging, active
  dischargingActive,

  /// not charging, inactive
  dischargingInactive;

  static const _featureStringMap = {
    unknown: 'UNKNOWN',
    charging: 'CHARGING',
    dischargingActive: 'DISCHARGING_ACTIVE',
    dischargingInactive: 'DISCHARGING_INACTIVE',
  };

  static final _stringFeatureMap =
      _featureStringMap.map((k, v) => MapEntry(v, k));

  /// Create a [PolarChargeState] from json
  static PolarChargeState fromJson(dynamic json) {
    if (Platform.isIOS) {
      return PolarChargeState.values[json as int];
    } else {
      // This is android
      return _stringFeatureMap[json as String]!;
    }
  }

  /// Convert a [PolarChargeState] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return PolarChargeState.values.indexOf(this);
    } else {
      // This is Android
      return _featureStringMap[this]!;
    }
  }
}
