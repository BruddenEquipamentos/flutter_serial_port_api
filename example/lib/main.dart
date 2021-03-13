import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  bool isPortOpened = false;
  SerialPort _serialPort;
  StreamSubscription _subscription;
  bool isHexMode = true;
  String readData = '';

  List<String> pathList = <String>[];
  String sPortPath = '';
  List<int> baudrateList = <int>[0,50,75,110,134,150,200,300,600,1200,1800,2400,4800,9600,19200,38400,57600,115200,230400,460800,500000,576000,921600,1000000,1152000,1500000,2000000,2500000,3000000,3500000,4000000];
  int baudrate = 115200;
  List<int> parityList = <int>[0, 1, 2];
  int parity = 0;
  List<int> dataBitsList = <int>[5, 6, 7, 8];
  int dataBits = 8;
  List<int> stopBitList = <int>[1, 2];
  int stopBit = 1;
  String writeData = '';

  _initPortList() async {
    List<Device> deviceList = await FlutterSerialPortApi.listDevices();
    if(null != deviceList && deviceList.isNotEmpty){
      sPortPath = deviceList[0].path;
      deviceList.forEach((device) {
        pathList.add(device.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initPortList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
//          Text('Running on: $_platformVersion\n')
          child: Column(
            children: [
              Container(
                color: Colors.black,
                width: double.infinity,
                height: 300,
                child: Text('$readData', style: TextStyle(color: Colors.white)),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: sPortPath,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String newValue) {
                      setState(() {
                        sPortPath = newValue;
                      });
                    },
                    items: pathList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  DropdownButton<int>(
                    value: baudrate,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        baudrate = newValue;
                      });
                    },
                    items: baudrateList.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                  Text('奇偶校验: '),
                  DropdownButton<int>(
                    value: parity,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        parity = newValue;
                      });
                    },
                    items: parityList.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('数据位: '),
                  DropdownButton<int>(
                    value: dataBits,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        dataBits = newValue;
                      });
                    },
                    items: dataBitsList.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                  Text('停止位: '),
                  DropdownButton<int>(
                    value: stopBit,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (int newValue) {
                      setState(() {
                        stopBit = newValue;
                      });
                    },
                    items: stopBitList.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        final debounceTransformer =
                        StreamTransformer<Uint8List,
                            dynamic>.fromBind(
                                (s) => s.transform(debounceBuffer(
                                const Duration(
                                    milliseconds: 500))));
                        if (!isPortOpened) {
                          if(sPortPath == ''){
                            Fluttertoast.showToast(msg: '请选择串口！', toastLength: Toast.LENGTH_SHORT);
                            return;
                          }
                          Device theDevice = Device(sPortPath, sPortPath);
                          var serialPort = await FlutterSerialPortApi.createSerialPort(theDevice, baudrate, parity: parity, dataBits: dataBits, stopBit: stopBit);
                          bool openResult = await serialPort.open();
                          setState(() {
                            _serialPort = serialPort;
                            isPortOpened = openResult;
                          });
                          _subscription = _serialPort.receiveStream
                              .transform(debounceTransformer)
                              .listen((recv) {
                            print("Receive: $recv");
                            String recvData = formatReceivedData(recv);
                            setState(() {
                              readData += '\n\r>>>[$sPortPath]>>> $recvData';
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
                      child: !isPortOpened ? Text("开启") : Text("关闭")
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                      ),
                      onChanged: _textFieldChanged,
                      autofocus: false,
                    ),
                  ),
                  ElevatedButton(
                      onPressed: (){
                        if(_serialPort == null){
                          Fluttertoast.showToast(msg: '请先打开串口！', toastLength: Toast.LENGTH_SHORT);
                          return;
                        }
                        _serialPort.write(Uint8List.fromList(hexToUnits(writeData)));
                      },
                      child: Text('发送')
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _textFieldChanged(String str) {
    writeData = str;
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