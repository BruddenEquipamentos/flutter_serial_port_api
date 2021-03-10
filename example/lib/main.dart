import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:stream_transform/stream_transform.dart';

import 'package:flutter/services.dart';
import 'package:flutter_serial_port_api/flutter_serial_port_api.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  bool isPortOpened = false;
  SerialPort _serialPort;
  StreamSubscription _subscription;
  List<Widget> _historyData = [];
  bool isHexMode = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterSerialPortApi.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
//          Text('Running on: $_platformVersion\n')
          child: Column(
            children: [
              InkWell(
                onTap: () async {
                  final debounceTransformer =
                  StreamTransformer<Uint8List,
                      dynamic>.fromBind(
                          (s) => s.transform(debounceBuffer(
                          const Duration(
                              milliseconds: 500))));
                  if (!isPortOpened) {
                    Device theDevice = Device("ttyS1", "/dev/ttyS1");
                    int baudrate = 9600;
                    var serialPort = await FlutterSerialPortApi.createSerialPort(theDevice, baudrate);
                    bool openResult = await serialPort.open();
                    setState(() {
                      _serialPort = serialPort;
                      isPortOpened = openResult;
                    });
                    _subscription = _serialPort.receiveStream
                        .transform(debounceTransformer)
                        .listen((recv) {
                      print("Receive: $recv");
                      String recvData =
                      formatReceivedData(recv);
                      setState(() {
                        _historyData
                            .add(Text(">>> $recvData"));
                      });
                    });
                  }else {
                    bool closeResult =
                    await _serialPort.close();
                    setState(() {
                      _serialPort = null;
                      isPortOpened = !closeResult;
                    });
                    _subscription = null;
                    print("closeResult: $closeResult");
                  }
                },
                child: !isPortOpened ? Text("Open") : Text("Close"),
              ),
              InkWell(
                onTap:() async {
                  _serialPort.write(Uint8List.fromList(hexToUnits('AABBCCDD')));
                },
                child:Text('write : AABBCCDD'),
              )
            ],
          ),
        ),
      ),
    );
  }

  String intToHex(int i, {int pad=2}) {
    return i.toRadixString(16).padLeft(pad, '0').toUpperCase();
  }

  List<int> hexToUnits(String hexStr, {int combine=2}) {
    hexStr = hexStr.replaceAll(" ", "");
    List<int> hexUnits = [];
    for(int i = 0;i < hexStr.length;i+=combine) {
      hexUnits.add(hexToInt(hexStr.substring(i, i+combine)));
    }
    return hexUnits;
  }

  int hexToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  String formatReceivedData(recv) {
    if (isHexMode) {
      return recv
          .map((List<int> char) => char.map((c) => intToHex(c)).join())
          .join();
    } else {
      return recv.map((List<int> char) => String.fromCharCodes(char)).join();
    }
  }

}