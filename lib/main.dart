import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';

import 'slider_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'PKCOINS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethClient;
  bool data = false;
  int myAmount = 0;
  late String txHash;

  final myAddress = "0xAAbadb8B44730d345a254eE1130b1827010E37f7";

  var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        "https://rinkeby.infura.io/v3/3224d071a8a04a1a92fdbf2ba9220286",
        httpClient);
    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x157B71b7497e46CC182642Aa01BEEFF6c31cDacB";

    final contract = DeployedContract(ContractAbi.fromJson(abi, "PKCoins"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final Contract = await loadContract();
    final ethFunction = Contract.function(functionName);
    final result = await ethClient.call(
        contract: Contract, function: ethFunction, params: args);

    return result;
  }

  Future<Void> getBalance(String targetAddress) async {
    //EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance", []);
    myData = result[0];
    data = true;
    return getBalance(targetAddress);
    setState(() {});
  }

  var value;

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "f7f7591056377fa64794d4a2534b363e0461483017ff6339f5f243b26bf4e489");

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
          contract: contract, function: ethFunction, parameters: args),
    );
    return result;
  }

  Future<Type> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositBalance", [bigAmount]);
    print("Deposited");
    txHash = response;
    setState(() {});
    return Response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withdrawBalance", [bigAmount]);
    print("Withdrawn");
    txHash = response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    var _value;
    return Scaffold(
        backgroundColor: Vx.gray300,
        body: ZStack([
          VxBox()
              .blueGray700
              .size(context.screenWidth, context.percentHeight * 30)
              .make(),
          VStack([
            (context.percentHeight * 10).heightBox,
            "\$PKCOINS".text.xl4.white.bold.center.makeCentered().py16(),
            (context.percentHeight * 5).heightBox,
            VxBox(
                    child: VStack([
              "BALANCE".text.gray700.xl2.semiBold.makeCentered(),
              10.heightBox,
              data
                  ? "\$$myData".text.bold.xl6.makeCentered().shimmer()
                  : CircularProgressIndicator().centered()
            ]))
                .p16
                .white
                .size(context.screenWidth, context.percentHeight * 18)
                .rounded
                .shadowXl
                .make()
                .p16(),
            30.heightBox,
            SliderWidget(
              min: 0,
              max: 100,
              finalVal: (value) {
                myAmount = (value * 100).round();
                print(myAmount);
              },
            ).centered(),
            HStack(
              [
                FlatButton.icon(
                        onPressed: () => getBalance(myAddress),
                        color: Colors.green,
                        shape: Vx.roundedSm,
                        icon: Icon(Icons.refresh, color: Colors.white),
                        label: "REFRESH".text.white.make())
                    .h(40),
                FlatButton.icon(
                        onPressed: () => sendCoin(),
                        color: Colors.black45,
                        shape: Vx.roundedSm,
                        icon: Icon(Icons.call_made_outlined,
                            color: Colors.lightGreen),
                        label: "DEPOSIT".text.white.make())
                    .h(40),
                FlatButton.icon(
                        onPressed: () => withdrawCoin(),
                        color: Colors.black45,
                        shape: Vx.roundedSm,
                        icon: Icon(Icons.call_received_outlined,
                            color: Colors.redAccent),
                        label: "WITHDRAW".text.white.make())
                    .h(40)
              ],
              alignment: MainAxisAlignment.spaceAround,
              axisSize: MainAxisSize.max,
            ).p16(),
            // ignore: unnecessary_null_comparison
            if (txHash != null) txHash.text.black.makeCentered().p16()
          ])
        ]));
  }
}
