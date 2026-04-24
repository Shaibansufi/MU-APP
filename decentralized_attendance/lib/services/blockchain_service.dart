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
      "http://192.168.31.24:7545",
      Client(),
    );

    _credentials = EthPrivateKey.fromHex(
      "0xd53afddad4c5173df201c1fa13f72628517500bf4e5a9efaaaf15ab652919606",
    );
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final abiString = await rootBundle.loadString("assets/educhain_abi.json");

    _contractAddress = EthereumAddress.fromHex(
      "0xb2658b29D9Cc2795232B71AA5293d4a759cEC391",
    );

    _contract = DeployedContract(
      ContractAbi.fromJson(abiString, "EduChainSecure"),
      _contractAddress,
    );

    _isInitialized = true;
  }

  // REGISTER USER
  Future<String> registerUser({
    required String prn,
    required String mobile,
    required String name,
    required String role,
    required String department,
    required String college,
    required String deviceAddress,
  }) async {
    await init();

    final EthPrivateKey privateKey =
        EthPrivateKey.createRandom(Random.secure());

    final String privateKeyHex =
        "0x${privateKey.privateKeyInt.toRadixString(16)}";

    final EthereumAddress userAddress =
        await privateKey.extractAddress();

    await _storage.write(
      key: "pk_$prn",
      value: privateKeyHex,
    );

    await _client.sendTransaction(
      _credentials,
      Transaction(
        to: userAddress,
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
      ),
      chainId: 1337,
    );

    final function = _contract.function("registerUser");

    final txHash = await _client.sendTransaction(
      privateKey,
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
          userAddress,
        ],
        maxGas: 300000,
      ),
      chainId: 1337,
    );

    return txHash;
  }

  // LOGIN USER
  Future<String> loginByMobile(String mobile, String prn) async {
    await init();

    final String? pk = await _storage.read(key: "pk_$prn");

    if (pk == null) {
      throw Exception("User not registered on this device");
    }

    final EthPrivateKey privateKey =
        EthPrivateKey.fromHex(pk);

    final EthereumAddress userAddress =
        await privateKey.extractAddress();

    final function = _contract.function("login");

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

  // MARK ATTENDANCE
  Future<String> markAttendance(String prn) async {
    await init();

    final function = _contract.function("markAttendance");

    final txHash = await _client.sendTransaction(
      _credentials,
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

  // VIEW ATTENDANCE
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
        .map<DateTime>(
          (ts) => DateTime.fromMillisecondsSinceEpoch(
            (ts as BigInt).toInt() * 1000,
          ),
        )
        .toList();
  }

  // MARK ATTENDANCE WITH SESSION
  Future<String> markAttendanceWithSession(
    String prn,
    String sessionId,
  ) async {
    await init();

    final function = _contract.function("markAttendanceWithSession");

    final txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [prn, sessionId],
        maxGas: 200000,
      ),
      chainId: 1337,
    );

    return txHash;
  }
}