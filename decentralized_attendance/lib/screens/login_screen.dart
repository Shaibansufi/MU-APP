import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/blockchain_service.dart';
import '../utils/utils.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final BlockchainService blockchainService;
  const LoginScreen({Key? key, required this.blockchainService})
      : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _prnCheckController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final Color primaryBrown = const Color(0xFF6D4C41);
  final Color accentOrange = const Color(0xFFFFA726);

  @override
  void dispose() {
    _mobileController.dispose();
    _prnCheckController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool isAuthenticated = await BiometricService().authenticate();
      if (!isAuthenticated) {
        _showMessage("Biometric Authentication Failed");
        setState(() => _isLoading = false);
        return;
      }

      String mobile = _mobileController.text.trim();
      String prn = _prnCheckController.text.trim();

      if (prn.isEmpty) {
        _showMessage("Please enter PRN ❌");
        setState(() => _isLoading = false);
        return;
      }

      String result = await widget.blockchainService.loginByMobile(
        mobile,
        prn,
      );

      if (result.isEmpty || result == "false") {
        _showMessage("Invalid credentials ❌");
        setState(() => _isLoading = false);
        return;
      }

      // ✅ FIX: treat result as role (fallback safe)
      String role = result;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userName: mobile,
            userId: prn,
            role: role, // ✅ FIXED HERE
          ),
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains("not registered")) {
        _showMessage("User not found on this device ❌");
      } else if (errorMessage.contains("value out of range")) {
        _showMessage("Blockchain decoding error.\nRestart app and try again.");
      } else {
        _showMessage("Login Failed ❌\n$errorMessage");
      }
    }

    setState(() => _isLoading = false);
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
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage("assets/images/blockchain.png"),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "EduChain Secure Login",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration("Mobile Number"),
                              validator: (value) {
                                if (value == null || value.length != 10) {
                                  return "Enter valid 10-digit mobile number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _prnCheckController,
                              decoration: _inputDecoration("Enter PRN"),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _isLoading ? null : _loginUser,
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
                                        color: Colors.white)
                                    : const Text(
                                        "Login Securely",
                                        style: TextStyle(
                                          color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(child: _buildBody())
        : Scaffold(body: _buildBody());
  }
}