import 'dart:io';

import 'package:recase/recase.dart';

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

  /// Create a [PolarChargeState] from json
  static PolarChargeState fromJson(dynamic json) {
    if (Platform.isIOS) {
      return PolarChargeState.values.byName(json as String);
    } else {
      // This is android
      return PolarChargeState.values.byName((json as String).camelCase);
    }
  }

  /// Convert a [PolarChargeState] to json
  dynamic toJson() {
    if (Platform.isIOS) {
      return name;
    } else {
      // This is Android
      return name.snakeCase.toUpperCase();
    }
  }
}
