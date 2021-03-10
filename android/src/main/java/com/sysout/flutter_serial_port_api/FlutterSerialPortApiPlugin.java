package com.sysout.flutter_serial_port_api;

import java.lang.Thread;
import java.lang.Runnable;
import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.ArrayList;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.EventChannel;

/**
 * FlutterSerialPortApiPlugin
 */
public class FlutterSerialPortApiPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private static final String TAG = "FlutterSerialPortApiPlugin";
    private SerialPortFinder mSerialPortFinder = new SerialPortFinder();
    protected SerialPort mSerialPort;
    protected OutputStream mOutputStream;
    private InputStream mInputStream;
    private ReadThread mReadThread;
    private EventChannel.EventSink mEventSink;
    private Handler mHandler = new Handler(Looper.getMainLooper());

    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_serial_port_api");
        channel.setMethodCallHandler(this);
        final EventChannel eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_serial_port_api/event");
        eventChannel.setStreamHandler(this);
    }

    private class ReadThread extends Thread {
        @Override
        public void run() {
            super.run();
            while (!isInterrupted()) {
                int size;
                try {
                    byte[] buffer = new byte[1024];
                    if (mInputStream == null)
                        return;
                    size = mInputStream.read(buffer);
                    // Log.d(TAG, "read size: " + String.valueOf(size));
                    if (size > 0) {
                        onDataReceived(buffer, size);
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                    return;
                }
            }
        }
    }

    protected void onDataReceived(final byte[] buffer, final int size) {
        if (mEventSink != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    // Log.d(TAG, "eventsink: " + buffer.toString());
                    mEventSink.success(Arrays.copyOfRange(buffer, 0, size));
                }
            });
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "open":
                final String devicePath = call.argument("devicePath");
                final int baudrate = call.argument("baudrate");
                final int parity = call.argument("parity");
                final int dataBits = call.argument("dataBits");
                final int stopBit = call.argument("stopBit");
                Log.d(TAG, "Open " + devicePath + ", baudrate: " + baudrate + ", parity: " + parity + ", dataBits: " + dataBits + ", stopBit: " + stopBit);
                Boolean openResult = openDevice(devicePath, baudrate, parity, dataBits, stopBit);
                result.success(openResult);
                break;
            case "close":
                Boolean closeResult = closeDevice();
                result.success(closeResult);
                break;
            case "write":
                Boolean writeResult = writeData((byte[]) call.argument("data"));
                result.success(writeResult);
                break;
            case "getAllDevices":
                ArrayList<String> devices = getAllDevices();
                Log.d(TAG, "AllDevices:" + devices.toString());
                result.success(devices);
                break;
            case "getAllDevicesPath":
                ArrayList<String> devicesPath = getAllDevicesPath();
                Log.d(TAG, "AllDevicesPath:" + devicesPath.toString());
                result.success(devicesPath);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        mEventSink = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        mEventSink = null;
    }

    private ArrayList<String> getAllDevices() {
        ArrayList<String> devices = new ArrayList<String>(Arrays.asList(mSerialPortFinder.getAllDevices()));
        return devices;
    }

    private ArrayList<String> getAllDevicesPath() {
        ArrayList<String> devicesPath = new ArrayList<String>(Arrays.asList(mSerialPortFinder.getAllDevicesPath()));
        return devicesPath;
    }

    private Boolean openDevice(String devicePath, int baudrate, int parity, int dataBits, int stopBit) {
        if (mSerialPort == null) {
            /* Check parameters */
            if ((devicePath.length() == 0) || (baudrate == -1)) {
                return false;
            }

            /* Open the serial port */
            try {
                mSerialPort = new SerialPort(new File(devicePath), baudrate, parity, dataBits, stopBit, 0);
                mOutputStream = mSerialPort.getOutputStream();
                mInputStream = mSerialPort.getInputStream();
                mReadThread = new ReadThread();
                mReadThread.start();
                return true;
            } catch (Exception e) {
                Log.e(TAG, e.toString());
                return false;
            }
        }
        return false;
    }

    private Boolean closeDevice() {
        try{
            if(null != mReadThread){
                mReadThread.interrupt();
                mReadThread = null;
            }
            if(null != mInputStream){
                mInputStream.close();
                mInputStream = null;
            }
            if(null != mOutputStream){
                mOutputStream.close();
                mOutputStream = null;
            }
            if (mSerialPort != null) {
                mSerialPort.close();
                mSerialPort = null;
            }
            return true;
        }catch (Exception e){
            e.printStackTrace();
        }
        return false;
    }

    private Boolean writeData(byte[] data) {
        try {
            if(null == mOutputStream) return false;
            mOutputStream.write(data);
            // mOutputStream.write('\n');
            return true;
        } catch (IOException e) {
            Log.e(TAG, e.toString());
            return false;
        }
    }
}
