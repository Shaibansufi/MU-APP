import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class BlockchainService {
  late Web3Client _client;
  late DeployedContract _contract;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;

  bool _isInitialized = false;

  BlockchainService() {
    _client = Web3Client(
      "http://192.168.3.230:7545", // Ganache RPC
      Client(),
    );

    _credentials = EthPrivateKey.fromHex(
      "0x54d42ffc99845453fa9b7ecf7cf3704fe8bf3ce43d5fdb92def3c8fdc6699822",
    );
  }

  // Initialize contract
  Future<void> init() async {
    if (_isInitialized) return;

    final abiString = await rootBundle.loadString("assets/educhain_abi.json");

    _contractAddress = EthereumAddress.fromHex(
      "0xCa655c606D40C1973d295155389bb3983db83951",
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
    required String deviceAddress, // string
  }) async {
    await init();

    final function = _contract.function("registerUser");

    final txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [prn, mobile, name, role, department, college, deviceAddress],
        maxGas: 300000,
      ),
      chainId: 1337,
    );

    return txHash;
  }

  // LOGIN USER
  Future<String> loginByMobile(String mobile, String deviceAddress) async {
    await init();

    final function = _contract.function("loginByMobile");

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [mobile, deviceAddress],
    );

    if (result.isEmpty) return "";

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
        .map<DateTime>((ts) => DateTime.fromMillisecondsSinceEpoch((ts as BigInt).toInt() * 1000))
        .toList();
  }
}