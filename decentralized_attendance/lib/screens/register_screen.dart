import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/biometric_service.dart';
import '../services/blockchain_service.dart';
import 'login_screen.dart';
import '../utils/utils.dart';


class RegisterScreen extends StatefulWidget {
  final BlockchainService blockchainService;
  const RegisterScreen({Key? key, required this.blockchainService})
      : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _prnController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();

  String _selectedRole = "Student";
  bool _isLoading = false;

  final Color primaryBrown = const Color(0xFF6D4C41);
  final Color accentOrange = const Color(0xFFFFA726);

  @override
  void dispose() {
    _prnController.dispose();
    _mobileController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentOrange, width: 2),
      ),
    );
  }

  void _showMessage(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Notice"),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Get Device ID
      String deviceId = await getDeviceId();

      // Step 2: Biometric Authentication
      bool isAuthenticated = await BiometricService().authenticate();
      if (!isAuthenticated) {
        _showMessage("Biometric Authentication Failed");
        setState(() => _isLoading = false);
        return;
      }

      // Step 3: Blockchain Registration with Device ID
      await widget.blockchainService.registerUser(
        prn: _prnController.text.trim(),
        mobile: _mobileController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        department: _departmentController.text.trim(),
        college: _collegeController.text.trim(),
        deviceAddress: deviceId,
      );
      print("Registering mobile: '${_mobileController.text.trim()}' with device: $deviceId");
      _showMessage("Registration Successful! ✅");

      // Step 4: Navigate to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LoginScreen(blockchainService: widget.blockchainService),
        ),
      );

      _formKey.currentState!.reset();
      _prnController.clear();
      _mobileController.clear();
      _nameController.clear();
      _departmentController.clear();
      _collegeController.clear();
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains("User already registered")) {
        _showMessage("PRN / Employee ID already registered ❌");
      } else if (errorMessage.contains("Mobile already registered")) {
        _showMessage("Mobile number already registered ❌");
      } else if (errorMessage.contains("value out of range")) {
        _showMessage(
            "Blockchain decoding error. Please restart app and try again.");
      } else {
        _showMessage("Registration Failed ❌\n$errorMessage");
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(child: _buildBody())
        : Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/images/university.png",
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.white.withOpacity(0.90)),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentOrange.withOpacity(0.3),
                          blurRadius: 25,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 55,
                      backgroundImage:
                          AssetImage("assets/images/blockchain.png"),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "EduChain Registration",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: _inputDecoration("Select Role"),
                              items: ["Student", "Teacher"]
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedRole = value!),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _prnController,
                              decoration: _inputDecoration(
                                  _selectedRole == "Student"
                                      ? "PRN Number"
                                      : "Employee ID"),
                              validator: (value) => value == null || value.isEmpty
                                  ? "This field is required"
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration("Mobile Number"),
                              validator: (value) => value == null ||
                                      value.length != 10
                                  ? "Enter valid 10-digit mobile"
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration("Full Name"),
                              validator: (value) => value == null || value.isEmpty
                                  ? "Enter your name"
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _departmentController,
                              decoration: _inputDecoration("Department"),
                              validator: (value) => value == null || value.isEmpty
                                  ? "Enter Department"
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _collegeController,
                              decoration: _inputDecoration("College Name"),
                              validator: (value) => value == null || value.isEmpty
                                  ? "Enter College Name"
                                  : null,
                            ),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap: _isLoading ? null : _registerUser,
                              child: Container(
                                height: 55,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accentOrange, primaryBrown],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Register with Biometric",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}