import 'dart:async';

import 'package:flutter/services.dart';

class FlutterSerialPortApi {
  static const MethodChannel _channel =
      MethodChannel('flutter_serial_port_api');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// List all devices
  static Future<List<Device>> listDevices() async {
    final List<dynamic> devices =
        await _channel.invokeMethod('getAllDevices');
    final List<dynamic> devicesPath =
        await _channel.invokeMethod('getAllDevicesPath');

    final List<Device> deviceList = [];
    devices.asMap().forEach((index, deviceName) {
      deviceList.add(Device(deviceName as String, devicesPath[index] as String));
    });
    return deviceList;
  }

  /// Create an [SerialPort] instance
  static Future<SerialPort> createSerialPort(
    Device device,
    int baudrate, {
    int parity = 0,
    int dataBits = 8,
    int stopBit = 1,
  }) async {
    return SerialPort(
      _channel.name,
      device,
      baudrate,
      parity,
      dataBits,
      stopBit,
    );
  }
}

class SerialPort {
  late final MethodChannel _channel;
  late final EventChannel _eventChannel;
  Stream<Uint8List>? _eventStream;
  Device device;
  int baudrate;
  int parity;
  int dataBits;
  int stopBit;
  bool _deviceConnected = false;

  SerialPort(
    String methodChannelName,
    this.device,
    this.baudrate,
    this.parity,
    this.dataBits,
    this.stopBit,
  ) {
    _channel = MethodChannel(methodChannelName);
    _eventChannel = EventChannel('$methodChannelName/event');
  }

  bool get isConnected => _deviceConnected;

  /// Stream(Event) coming from Android
  Stream<Uint8List> get receiveStream {
    _eventStream = _eventChannel
        .receiveBroadcastStream()
        .map<Uint8List>((dynamic value) => value as Uint8List);
    return _eventStream!;
  }

  @override
  String toString() {
    return 'SerialPort($device, $baudrate, $parity, $dataBits, $stopBit)';
  }

  /// Open device
  Future<bool> open() async {
    final bool openResult = await _channel.invokeMethod(
      'open',
      {
        'devicePath': device.path,
        'baudrate': baudrate,
        'parity': parity,
        'dataBits': dataBits,
        'stopBit': stopBit,
      },
    );

    if (openResult) {
      _deviceConnected = true;
    }

    return openResult;
  }

  /// Close device
  Future<bool> close() async {
    final bool closeResult = await _channel.invokeMethod('close');

    if (closeResult) {
      _deviceConnected = false;
    }

    return closeResult;
  }

  /// Write data to device
  Future<void> write(Uint8List data) async {
    await _channel.invokeMethod('write', {'data': data});
  }
}

/// [Device] contains device information(name and path).
class Device {
  final String name;
  final String path;

  Device(this.name, this.path);

  @override
  String toString() {
    return 'Device($name, $path)';
  }
}
