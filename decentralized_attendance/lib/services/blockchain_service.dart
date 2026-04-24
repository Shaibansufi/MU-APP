import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
class BlockchainService {
  late Web3Client _client;
  late DeployedContract _contract;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isInitialized = false;

  BlockchainService() {
    _client = Web3Client(
      "http://192.168.31.24:7545", // Ganache RPC
      Client(),
    );

    // ⚠️ Admin account (still used for other functions)
    _credentials = EthPrivateKey.fromHex(
      "0xd53afddad4c5173df201c1fa13f72628517500bf4e5a9efaaaf15ab652919606",
    );
  }

  // Initialize contract
  Future<void> init() async {
    if (_isInitialized) return;

    final abiString = await rootBundle.loadString("assets/educhain_abi.json");

    _contractAddress = EthereumAddress.fromHex(
      "0xCc2e0B48F0622F4A0fb63e91F7a36ca59d32aD3F",
    );

    _contract = DeployedContract(
      ContractAbi.fromJson(abiString, "EduChainSecure"),
      _contractAddress,
    );

    _isInitialized = true;
  }

  // ✅ UPDATED REGISTER USER (WALLET BASED)
  Future<String> registerUser({
    required String prn,
    required String mobile,
    required String name,
    required String role,
    required String department,
    required String college,
    required String deviceAddress, // UI se aa raha hai (ignore karenge)
  }) async {
    await init();

    // 🔐 1. Generate user wallet
    final EthPrivateKey privateKey = EthPrivateKey.createRandom(Random.secure());

    final String privateKeyHex =
        "0x${privateKey.privateKeyInt.toRadixString(16)}";

    final EthereumAddress userAddress =
        await privateKey.extractAddress();


    // 🔐 2. Store private key locally
    await _storage.write(
      key: "pk_$prn",
      value: privateKeyHex,
    );

// ⭐ 3. FUND NEW WALLET (ADD THIS PART)
    await _client.sendTransaction(
      _credentials, // admin wallet (has ETH)
      Transaction(
        to: userAddress,
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
      ),
      chainId: 1337,
    );

// 4. Now safe to call contract
    final function = _contract.function("registerUser");

    // 🚀 4. Send transaction using USER wallet (NOT admin)
    final txHash = await _client.sendTransaction(
      privateKey, // ✅ USER wallet
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [
          prn,
          mobile,
          name,
          role,
          department,
          college,
          userAddress, // ✅ wallet address instead of deviceAddress
        ],
        maxGas: 300000,
      ),
      chainId: 1337,
    );

    return txHash;
  }

  // LOGIN USER (UNCHANGED)


Future<String> loginByMobile(String mobile, String prn) async {
  await init();

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // 🔐 1. Get stored private key
  String? pk = await storage.read(key: "pk_$prn");

  if (pk == null) {
    throw Exception("User not registered on this device");
  }

  // 🔐 2. Recreate wallet
  final EthPrivateKey privateKey = EthPrivateKey.fromHex(pk);
  final EthereumAddress userAddress =
      await privateKey.extractAddress();

  // 📜 3. Contract function
  final function = _contract.function("login");

  // 🔍 4. Call contract (no gas, read-only)
  final result = await _client.call(
    contract: _contract,
    function: function,
    params: [mobile, userAddress],
  );

  if (result.isEmpty) {
    throw Exception("Login failed");
  }

  return result.first.toString();
}
  // MARK ATTENDANCE (UNCHANGED)
  Future<String> markAttendance(String prn) async {
    await init();

    final function = _contract.function("markAttendance");

    final txHash = await _client.sendTransaction(
      _credentials, // still admin (can upgrade later)
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [prn],
        maxGas: 200000,
      ),
      chainId: 1337,
    );

    return txHash;
  }

  // VIEW ATTENDANCE (UNCHANGED)
  Future<List<DateTime>> viewAttendance(String prn) async {
    await init();

    final function = _contract.function("getAttendance");

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [prn],
    );

    if (result.isEmpty) return [];

    List<dynamic> timestamps = result.first;

    return timestamps
        .map<DateTime>((ts) =>
            DateTime.fromMillisecondsSinceEpoch((ts as BigInt).toInt() * 1000))
        .toList();
  }
}