import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model untuk simpan config printer ke SharedPreferences
class PrinterConfig {
  String name;
  String macAddress;
  int paperSize; // 58 atau 80 (mm)

  PrinterConfig({
    required this.name,
    required this.macAddress,
    this.paperSize = 58,
  });

  // ===== JSON Serialization =====
  Map<String, dynamic> toJson() => {
        'name': name,
        'macAddress': macAddress,
        'paperSize': paperSize,
      };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) => PrinterConfig(
        name: json['name'] ?? '',
        macAddress: json['macAddress'] ?? '',
        paperSize: json['paperSize'] ?? 58,
      );

  // ===== SharedPreferences =====
  static const String _key = 'saved_printer_config';

  /// Load printer tersimpan dari SharedPreferences
  static Future<PrinterConfig?> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null) return null;

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final config = PrinterConfig.fromJson(map);
      print('[PRINTER CONFIG] ✅ Loaded: ${config.name} (${config.macAddress})');
      return config;
    } catch (e) {
      print('[PRINTER CONFIG] ❌ Load error: $e');
      return null;
    }
  }

  /// Simpan printer ke SharedPreferences
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(toJson()));
      print('[PRINTER CONFIG] ✅ Saved: $name ($macAddress)');
    } catch (e) {
      print('[PRINTER CONFIG] ❌ Save error: $e');
    }
  }

  /// Hapus printer tersimpan
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      print('[PRINTER CONFIG] ✅ Cleared');
    } catch (e) {
      print('[PRINTER CONFIG] ❌ Clear error: $e');
    }
  }

  /// Update paper size saja
  Future<void> updatePaperSize(int size) async {
    paperSize = size;
    await save();
  }

  @override
  String toString() => 'PrinterConfig($name, $macAddress, ${paperSize}mm)';
}
