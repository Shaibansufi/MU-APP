import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Returns a unique device ID for Android and iOS
Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    // 'id' is a stable unique identifier per device
    return androidInfo.id ?? '';
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    // Identifier for vendor is unique per app per device
    return iosInfo.identifierForVendor ?? '';
  } else {
    // Fallback for other platforms
    return '';
  }
}