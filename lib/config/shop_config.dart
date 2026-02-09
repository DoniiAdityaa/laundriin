import 'package:cloud_firestore/cloud_firestore.dart';

/// Delivery & Shop Settings Configuration
///
/// File ini berisi settingan untuk delivery time, estimasi, dan konfigurasi toko.
/// ShopSettings sekarang sudah terintegrasi dengan Firestore.

class DeliveryConfig {
  /// Estimasi waktu pengerjaan Regular (dalam jam) - dari database
  static int regularEstimatedHours =
      48; // Default 48 jam (2 hari), bisa di-override

  /// Estimasi waktu pengerjaan Express (dalam jam) - dari database
  static int expressEstimatedHours =
      24; // Default 24 jam, bisa di-override dari database

  /// Format tampilan estimasi
  static String getEstimationText(bool isExpress) {
    if (isExpress) {
      return '$expressEstimatedHours Jam'; // Dynamic dari database
    } else {
      final days = (regularEstimatedHours / 24).toStringAsFixed(1);
      return '$regularEstimatedHours Jam (~$days hari)'; // Dynamic dari database
    }
  }

  /// Hitung waktu selesai berdasarkan order time dan speed
  static DateTime calculateEstimatedCompletion(
      DateTime orderTime, bool isExpress) {
    if (isExpress) {
      // Express: selesai dalam jam yang ditentukan di database
      return orderTime.add(Duration(hours: expressEstimatedHours));
    } else {
      // Regular: selesai dalam jam yang ditentukan di database
      return orderTime.add(Duration(hours: regularEstimatedHours));
    }
  }

  /// Load settings dari Firestore /users/{userId}/pricing/
  static Future<void> loadFromDatabase(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final pricing = doc.data()!['pricing'] ?? {};
        regularEstimatedHours = pricing['regularEstimatedHours'] ?? 48;
        expressEstimatedHours = pricing['expressEstimatedHours'] ?? 24;

        print('[DELIVERY CONFIG] ✅ Loaded from Firestore');
        print('  - Regular Hours: $regularEstimatedHours jam');
        print('  - Express Hours: $expressEstimatedHours jam');
      } else {
        print('[DELIVERY CONFIG] ⚠️ Pricing document tidak ditemukan');
      }
    } catch (e) {
      print('[ERROR] Load delivery config: $e');
      // Gunakan default value
    }
  }
}

class ShopSettings {
  /// Nama toko (dari Firestore) - Default: Cendana
  static String shopName = 'Cendana';

  /// Nama owner/kasir (dari Firestore) - Default: Admin
  static String ownerName = 'Admin';

  /// Alamat toko (dari Firestore) - Default: sekuri
  static String shopAddress = 'sekuro';

  /// Nomor telepon toko (dari Firestore) - Default: 089682941139
  static String shopPhone = '0123456789';

  /// Nama kasir (sama dengan owner, dari Firestore)
  static String get currentUserName => ownerName;

  /// Load shop settings dari Firestore /shop_information/{userId}
  static Future<void> loadFromFirestore(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final shopInfo = data['shopInfo'] ?? {};

        shopName = shopInfo['shopName'] ?? 'Cendana';
        ownerName = shopInfo['ownerName'] ?? 'Admin';
        shopAddress = shopInfo['address'] ?? 'sekuri';
        shopPhone = shopInfo['whatsapp'] ?? '0123456789';

        print(
            '[SHOP SETTINGS] ✅ Loaded from Firestore (users/{userId}/shopInfo)');
        print('  - Shop Name: $shopName');
      } else {
        print('[SHOP SETTINGS] ⚠️ user doc tidak ditemukan');
      }
    } catch (e) {
      print('[ERROR] Load shop settings failed: $e');
    }
  }
}

class DiscountConfig {
  /// Diskon member (persen)
  static const double memberDiscount = 10.0;

  /// Diskon untuk pembelian paket (persen)
  static const double bundleDiscount = 15.0;

  /// Minimal order untuk free ongkir
  static const int minOrderForFreeShip = 50000;
}

class NotificationConfig {
  /// Send reminder 1 jam sebelum selesai
  static const bool enableReminder = true;

  /// Send dreminder via WhatsApp
  static const bool reminderViaWhatsApp = true;

  /// Send invoice via WhatsApp setelah order
  static const bool invoiceViaWhatsApp = true;
}
