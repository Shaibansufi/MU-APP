import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/blockchain_service.dart';
import '../services/teacher_beacon_service.dart';
import '../services/student_scanner_service.dart';

class DashboardScreen extends StatelessWidget {
  final String userName;
  final String role;
  final String userId;

  const DashboardScreen({
    Key? key,
    required this.userName,
    required this.role,
    required this.userId,
  }) : super(key: key);

  final Color primaryBrown = const Color(0xFF8D6E63);
  final Color accentOrange = const Color(0xFFFFB74D);
  final Color backgroundColor = const Color(0xFFFDF6EC);

  void _showMessage(BuildContext context, String msg) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Notice"),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(
            child: Container(
              color: backgroundColor,
              child: SafeArea(child: _buildBody(context)),
            ),
          )
        : Scaffold(
            backgroundColor: backgroundColor,
            body: SafeArea(child: _buildBody(context)),
          );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 30),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              children: [

                // ================= TEACHER =================
                if (role.trim().toLowerCase() == "teacher") ...[
                  _actionCard(
                    context: context,
                    title: "Mark Attendance",
                    subtitle: "Record on blockchain",
                    icon: Icons.check_circle_outline,
                    onTap: () async {
                      String tx =
                          await BlockchainService().markAttendance(userId);
                      _showMessage(context, "Attendance marked!\nTX: $tx");
                    },
                  ),

                  _actionCard(
                    context: context,
                    title: "View Attendance",
                    subtitle: "Check blockchain records",
                    icon: Icons.bar_chart,
                    onTap: () async {
                      var records =
                          await BlockchainService().viewAttendance(userId);
                      _showMessage(context, "Attendance: $records");
                    },
                  ),

                  _actionCard(
                    context: context,
                    title: "Start Attendance (BLE)",
                    subtitle: "Broadcast session to students",
                    icon: Icons.bluetooth,
                    onTap: () async {
                      await TeacherBeaconService().startBeacon("CS101");
                      _showMessage(context, "📡 BLE Attendance Started");
                    },
                  ),
                ],

                // ================= STUDENT =================
                if (role.trim().toLowerCase() == "student")
                  _actionCard(
                    context: context,
                    title: "Scan & Mark Attendance",
                    subtitle: "Detect teacher session via BLE",
                    icon: Icons.radar,
                    onTap: () {
                      StudentScannerService().startScan((sessionId) {
                        _showMessage(
                          context,
                          "📡 Session Found!\nMarking Attendance\nSession: $sessionId",
                        );

                        // 👉 SMART CONTRACT HOOK
                        // BlockchainService().markAttendance(userId, sessionId);
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        _logoutButton(context),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBrown, primaryBrown.withOpacity(0.85)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome,",
              style: TextStyle(color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 5),
          Text(userName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("$role Dashboard",
              style: TextStyle(color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 6),
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: accentOrange.withOpacity(0.2),
              child: Icon(icon, color: accentOrange, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 50,
        width: double.infinity,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryBrown),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}