import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import '../services/blockchain_service.dart';

class TestBlockchainScreen extends StatefulWidget {
  final BlockchainService blockchainService;

  const TestBlockchainScreen({super.key, required this.blockchainService});

  @override
  State<TestBlockchainScreen> createState() => _TestBlockchainScreenState();
}

class _TestBlockchainScreenState extends State<TestBlockchainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Blockchain")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    String tx = await widget.blockchainService.registerUser(
                      prn: "12345",
                      mobile: "9998887776",
                      name: "John Doe",
                      role: "Student",
                      department: "CS",
                      college: "XYZ College",
                      deviceAddress: "0x0000000000000000000000000000000000000000",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User Registered TX: $tx")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Register User"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    String tx = await widget.blockchainService.markAttendance(
                      "12345",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Attendance TX: $tx")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Mark Attendance"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    List<DateTime> attendance = await widget.blockchainService
                        .viewAttendance("12345");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Attendance Records: $attendance"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("View Attendance"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
