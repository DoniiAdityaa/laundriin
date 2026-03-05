import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:laundriin/printer_service/printer_config.dart';

/// Singleton untuk manage koneksi Bluetooth thermal printer
class PrinterManager {
  // ===== SINGLETON =====
  static final PrinterManager instance = PrinterManager._internal();
  factory PrinterManager() => instance;
  PrinterManager._internal();

  // ===== STATE =====
  bool _isConnected = false;
  PrinterConfig? _currentPrinter;
  List<BluetoothInfo> _scannedDevices = [];

  // ===== GETTERS =====
  bool get isConnected => _isConnected;
  PrinterConfig? get currentPrinter => _currentPrinter;
  List<BluetoothInfo> get scannedDevices => _scannedDevices;

  // ===== CHECK CONNECTION =====
  Future<bool> checkConnection() async {
    try {
      _isConnected = await PrintBluetoothThermal.connectionStatus;
      print('[PRINTER] Connection status: $_isConnected');
      return _isConnected;
    } catch (e) {
      print('[PRINTER] ❌ Check connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  // ===== SCAN DEVICES =====
  Future<List<BluetoothInfo>> scanDevices() async {
    try {
      print('[PRINTER] 🔍 Scanning Bluetooth devices...');

      // Request Bluetooth permissions dulu
      final granted = await _requestBluetoothPermissions();
      if (!granted) {
        print('[PRINTER] ⚠️ Bluetooth permissions belum diberikan');
        return [];
      }

      // Cek apakah Bluetooth aktif
      final isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isEnabled) {
        print('[PRINTER] ⚠️ Bluetooth tidak aktif');
        return [];
      }

      // Scan paired devices
      _scannedDevices = await PrintBluetoothThermal.pairedBluetooths;
      print('[PRINTER] ✅ Found ${_scannedDevices.length} paired devices');

      for (var device in _scannedDevices) {
        print('  - ${device.name} (${device.macAdress})');
      }

      return _scannedDevices;
    } catch (e) {
      print('[PRINTER] ❌ Scan error: $e');
      return [];
    }
  }

  // ===== REQUEST BLUETOOTH PERMISSIONS =====
  Future<bool> _requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 31) {
        // Android 12+ butuh BLUETOOTH_SCAN & BLUETOOTH_CONNECT
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

        final allGranted = statuses.values.every((s) => s.isGranted);
        print('[PRINTER] Bluetooth permissions (Android 12+): $allGranted');
        return allGranted;
      } else {
        // Android < 12 butuh Location untuk Bluetooth scanning
        final status = await Permission.location.request();
        print(
            '[PRINTER] Location permission (Android <12): ${status.isGranted}');
        return status.isGranted;
      }
    }

    // iOS tidak perlu request Bluetooth permission secara manual
    return true;
  }

  // ===== CONNECT =====
  Future<bool> connect(BluetoothInfo device) async {
    try {
      print('[PRINTER] 🔗 Connecting to ${device.name}...');

      // Disconnect dulu kalau masih connected
      if (_isConnected) {
        await disconnect();
      }

      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAdress,
      );

      _isConnected = result;

      if (result) {
        // Simpan sebagai printer terakhir
        _currentPrinter = PrinterConfig(
          name: device.name,
          macAddress: device.macAdress,
        );
        await _currentPrinter!.save();

        print('[PRINTER] ✅ Connected to ${device.name}');
      } else {
        print('[PRINTER] ❌ Failed to connect to ${device.name}');
      }

      return result;
    } catch (e) {
      print('[PRINTER] ❌ Connect error: $e');
      _isConnected = false;
      return false;
    }
  }

  // ===== DISCONNECT =====
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _isConnected = false;
      print('[PRINTER] 🔌 Disconnected');
    } catch (e) {
      print('[PRINTER] ❌ Disconnect error: $e');
    }
  }

  // ===== PRINT RECEIPT =====
  Future<bool> printReceipt(List<int> bytes) async {
    try {
      // Cek koneksi dulu
      final connected = await checkConnection();
      if (!connected) {
        print('[PRINTER] ⚠️ Printer tidak terhubung');
        return false;
      }

      print('[PRINTER] 🖨️ Printing ${bytes.length} bytes...');

      final result = await PrintBluetoothThermal.writeBytes(bytes);

      if (result) {
        print('[PRINTER] ✅ Print berhasil!');
      } else {
        print('[PRINTER] ❌ Print gagal');
      }

      return result;
    } catch (e) {
      print('[PRINTER] ❌ Print error: $e');
      return false;
    }
  }

  // ===== AUTO RECONNECT =====
  /// Coba reconnect ke printer terakhir yang tersimpan
  Future<bool> reconnectLastPrinter() async {
    try {
      // Load config printer terakhir
      final config = await PrinterConfig.loadSaved();
      if (config == null) {
        print('[PRINTER] ⚠️ Tidak ada printer tersimpan');
        return false;
      }

      print('[PRINTER] 🔄 Reconnecting to ${config.name}...');

      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: config.macAddress,
      );

      _isConnected = result;

      if (result) {
        _currentPrinter = config;
        print('[PRINTER] ✅ Reconnected to ${config.name}');
      } else {
        print('[PRINTER] ❌ Reconnect failed');
      }

      return result;
    } catch (e) {
      print('[PRINTER] ❌ Reconnect error: $e');
      _isConnected = false;
      return false;
    }
  }

  // ===== CHECK BLUETOOTH STATUS =====
  /// Cek Bluetooth aktif — request permission dulu baru cek status
  Future<bool> isBluetoothEnabled() async {
    try {
      // Request permission dulu sebelum cek Bluetooth
      final granted = await _requestBluetoothPermissions();
      if (!granted) {
        print('[PRINTER] ⚠️ Bluetooth permissions belum diberikan');
        return false;
      }
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      return false;
    }
  }

  // ===== FORGET PRINTER =====
  Future<void> forgetPrinter() async {
    await disconnect();
    await PrinterConfig.clear();
    _currentPrinter = null;
    print('[PRINTER] 🗑️ Printer forgotten');
  }
}
