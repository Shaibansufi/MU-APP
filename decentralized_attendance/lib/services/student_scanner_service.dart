import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class StudentScannerService {
  bool _marked = false;
  var _subscription;

  void startScan(Function(String sessionId) onFound) async {
    _marked = false;

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    _subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (_marked) return;

        final data = r.advertisementData.manufacturerData;

        if (data.isNotEmpty) {
          try {
            final bytes = data.values.first;

            // 🔥 FIX: safe decode (base64)
            final decodedBase64 = utf8.decode(bytes);
            final decodedJson =
                utf8.decode(base64Decode(decodedBase64));

            final jsonData = jsonDecode(decodedJson);

            if (jsonData["classId"] != null &&
                jsonData["session"] != null) {

              _marked = true;

              print("🎯 Teacher Found: $jsonData");

              String sessionId = jsonData["session"];

              onFound(sessionId);

              FlutterBluePlus.stopScan();
              _subscription.cancel(); // 🔥 FIX
              break;
            }
          } catch (e) {
            // ignore garbage
          }
        }
      }
    });
  }
}