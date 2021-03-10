# flutter_serial_port_api


基于 [Android-SerialPort-API](https://github.com/cepr/android-serialport-api) 的串口通讯库，增加可配置奇偶校验、数据位、停止位.

This plugin works only for Android devices.

## Usage

### dependencies

``` dart
flutter_serial_port_api:
    git:
      url: https://gitee.com/liang-fu/flutter_serial_port_api.git
      ref: V0.0.1   #通过ref指定依赖某个提交的版本、分支或者tag
```

### import

``` dart
import 'package:flutter_serial_port_api/flutter_serial_port_api.dart';
```

### List devices

``` dart
Future<List<Device>> findDevices() async {
  return await FlutterSerialPort.listDevices();
}
```

### Create `SerialPort` for certain device

``` dart
Device theDevice = Device("deviceName", "/your/device/path");
int baudrate = 9600;
var serialPort = await FlutterSerialPort.createSerialPort(theDevice, baudrate);
//int parity = 0;
//int dataBits = 8;
//int stopBit = 1;
//var serialPort = await FlutterSerialPort.createSerialPort(theDevice, baudrate, parity:parity, dataBits:dataBits, stopBit:stopBit);
```

### Open/Close device

``` dart
bool openResult = await serialPort.open();
print(serialPort.isConnected) // true
bool closeResult = await serialPort.close();
print(serialPort.isConnected) // false
```

### Read/Write data from/to device

``` dart
// Listen to `receiveStream`
serialPort.receiveStream.listen((recv) {
  print("Receive: $recv");
});

bool writeResult = serialPort.write(Uint8List.fromList("Write some data".codeUnits));
```