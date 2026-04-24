import 'dart:convert';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class TeacherBeaconService {
  final flutterBlePeripheral = FlutterBlePeripheral();

  Future<void> startBeacon(String classId) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final data = jsonEncode({
      "classId": classId,
      "session": sessionId,
    });

    // 🔥 FIX: BLE safe encoding
    final encoded = base64Encode(utf8.encode(data));

    final advertiseData = AdvertiseData(
      serviceUuid: "12345678-1234-1234-1234-1234567890ab",
      manufacturerId: 1234,
      manufacturerData: utf8.encode(encoded),
    );

    await flutterBlePeripheral.start(advertiseData: advertiseData);

    print("📡 Beacon Started: $data");
  }

  Future<void> stopBeacon() async {
    await flutterBlePeripheral.stop();
    print("🛑 Beacon Stopped");
  }
}