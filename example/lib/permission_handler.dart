import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionHandler {
  static Future<void> requestBluetoothPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }

    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }

    // For older versions (Android 11 and below)
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }
}
