# flutter_serial_port_api

Flutter plugin for Android serial port communication, built on [Android-SerialPort-API](https://github.com/cepr/android-serialport-api). Supports configurable parity, data bits, and stop bits.

**Platform:** Android only.

## Fork

This repository is a maintained fork of the original project:

- **Upstream:** [liang-fu/flutter_serial_port_api](https://gitee.com/liang-fu/flutter_serial_port_api) (Gitee)

It is published under [BruddenEquipamentos](https://github.com/BruddenEquipamentos) for use in current Flutter apps. Credit goes to the original authors; see upstream history for earlier changes.

## What changed in this fork

| Area | Changes |
|------|---------|
| **Hosting** | Moved to GitHub (`BruddenEquipamentos/flutter_serial_port_api`). |
| **Dart / Flutter** | Migrated to **Dart 3** and **Flutter 3.16+** (null-safe API, updated `pubspec` SDK constraints). |
| **Android** | Updated Gradle / Android build configuration for modern toolchains. |
| **Tests** | Adjusted unit tests for the updated API. |
| **Docs** | English README; dependency examples point at this GitHub repo. |

Package version **0.1.0** reflects the Dart 3 / Flutter 3.16+ migration. See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Usage

### Dependency

```yaml
dependencies:
  flutter_serial_port_api:
    git:
      url: https://github.com/BruddenEquipamentos/flutter_serial_port_api.git
      ref: master
```

### Import

```dart
import 'package:flutter_serial_port_api/flutter_serial_port_api.dart';
```

### List devices

```dart
Future<List<Device>> findDevices() async {
  return await FlutterSerialPort.listDevices();
}
```

### Create a `SerialPort` for a device

```dart
Device theDevice = Device("deviceName", "/your/device/path");
int baudrate = 9600;
var serialPort = await FlutterSerialPort.createSerialPort(theDevice, baudrate);

// Optional: parity, data bits, stop bits
// int parity = 0;
// int dataBits = 8;
// int stopBit = 1;
// var serialPort = await FlutterSerialPort.createSerialPort(
//   theDevice,
//   baudrate,
//   parity: parity,
//   dataBits: dataBits,
//   stopBit: stopBit,
// );
```

### Open and close

```dart
bool openResult = await serialPort.open();
print(serialPort.isConnected); // true

bool closeResult = await serialPort.close();
print(serialPort.isConnected); // false
```

### Read and write

```dart
serialPort.receiveStream.listen((recv) {
  print("Receive: $recv");
});

bool writeResult = serialPort.write(
  Uint8List.fromList("Write some data".codeUnits),
);
```

## License

See [LICENSE](LICENSE).
