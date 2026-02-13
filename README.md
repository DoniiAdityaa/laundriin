# 🧺 Laundriin

Aplikasi manajemen laundry berbasis Flutter yang dirancang untuk memudahkan pemilik laundry mengelola pesanan, harga layanan, dan pelanggan secara efisien. 3 service (Auth + Firestore + Cloudinary) = clean architecture

## 📋 Gambaran Proyek

Laundriin adalah aplikasi mobile untuk pemilik usaha laundry yang ingin:
- Mengelola pesanan pelanggan dengan mudah
- Mengatur harga layanan untuk berbagai jenis cuci
- Menyimpan data pelanggan
- Melacak status pesanan
- Menghitung total biaya secara otomatis

---

## ✨ Fitur-Fitur

### Core Features (Implemented)
- ✅ **Autentikasi & Akun**
  - Login dengan email & password
  - Registrasi akun toko laundry
  - Single-tenant architecture (1 akun = 1 toko)

- ✅ **Manajemen Pesanan (Add Order)**
  - **Step 1: Customer Info**
    - Input nama pelanggan (dengan search history)
    - Pilih jenis kelamin
    - Input nomor WhatsApp
    - Auto-save pelanggan baru
  
  - **Step 2: Service Selection**
    - Pilih kategori: Kiloan / Satuan / Campuran
    - Pilih jenis layanan (Komplit, Setrika, Kering, Uap)
    - Pilih kecepatan: Regular / Express
    - Input weight/quantity
    - Catatan khusus (opsional)
    - Automatic price calculation
  
  - **Step 3: Order Confirmation** (coming soon)

- ✅ **Dynamic Pricing System**
  - Harga cuci per kilo
  - Harga setrika
  - Harga cuci kering
  - Harga setrika uap
  - Biaya express surcharge
  - Daftar item satuan dengan harga custom

- ✅ **Manajemen Pelanggan**
  - Simpan data pelanggan
  - Search & autocomplete pelanggan existing
  - History pelanggan tersimpan

### Upcoming Features
- 📋 Order History & Tracking
- 📊 Business Analytics & Reports
- 💰 Payment & Invoice Management
- 🔔 Order Status Notifications
- 📲 WhatsApp Integration
- 🖨️ Receipt Printing
- 📱 Customer Mobile App

---

## 🗄️ Data Storage & Architecture

### Database: Firebase
1. **Firestore Database**
   ```
   /users/{userId}
   ├── profile (nama toko, alamat, kontak)
   ├── pricing (harga layanan)
   ├── orders (pesanan pelanggan)
   └── customers (data pelanggan)
   
   /shops/{shopId}
   ├── customers/{customerId} (detail pelanggan per toko)
   ├── orders/{orderId} (pesanan per toko)
   └── settings (pengaturan toko)
   ```

2. **Firebase Auth**
   - Email/Password authentication
   - User session management

3. **Firebase Storage** (untuk future)
   - Receipt images
   - Customer photos
   - Business documents

### Data Model
```dart
// Customer Model
{
  'id': String,
  'name': String,
  'phone': String,
  'gender': String ('Laki-laki' / 'Perempuan'),
  'createdAt': Timestamp,
  'updatedAt': Timestamp
}

// Order Model
{
  'id': String,
  'customerId': String,
  'category': String ('Kiloan' / 'Satuan' / 'Campuran'),
  'serviceType': String ('washComplete' / 'ironing' / 'dryWash' / 'steamIroning'),
  'speed': String ('Regular' / 'Express'),
  'weight': double (for Kiloan),
  'items': Map<itemId, qty> (for Satuan),
  'notes': String,
  'basePrice': int,
  'expressPrice': int,
  'totalPrice': int,
  'status': String ('pending' / 'processing' / 'completed'),
  'createdAt': Timestamp,
  'completedAt': Timestamp
}

// Pricing Model
{
  'pricePerKilo': int,
  'expressSurcharge': int,
  'ironing': int,
  'dryWash': int,
  'steamIroning': int,
  'nonKiloItems': [
    {
      'id': String,
      'name': String,
      'price': int
    }
  ]
}
```

---

## 🛣️ Development Roadmap

### Phase 1: MVP (Current - Week 8)
- [x] User authentication & registration
- [x] Customer information management
- [x] Dynamic pricing system
- [x] Add order with multi-step form
- [x] Service type selection (Kiloan only)
- [x] Automatic price calculation
- [ ] Order confirmation & summary
- [ ] Order placement to Firestore

### Phase 2: Core Features (Week 9-10)
- [ ] Order history & list view
- [ ] Order status tracking (pending → completed)
- [ ] Edit/cancel order functionality
- [ ] Order search & filter
- [ ] Daily sales report
- [ ] Customer transaction history

### Phase 3: Enhancement (Week 11-12)
- [ ] Satuan & Campuran category full support
- [ ] WhatsApp integration (send receipt link)
- [ ] Receipt/invoice generation
- [ ] Payment method tracking
- [ ] Business analytics dashboard
- [ ] Refund/adjustment handling

### Phase 4: Polish & Deploy (Week 13-14)
- [ ] UI/UX improvements
- [ ] Error handling & validation
- [ ] Performance optimization
- [ ] App testing & QA
- [ ] Google Play Store release
- [ ] App Store release (iOS)

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.x
- **Dart** 
- **Provider** / **Riverpod** (state management)
- **Firebase Plugins**

### Backend & Database
- **Firebase Authentication**
- **Firebase Firestore**
- **Firebase Cloud Functions** (for future)

### Tools & Packages
```yaml
dependencies:
  firebase_auth: ^4.x
  cloud_firestore: ^4.x
  firebase_core: ^2.x
  provider: ^6.x atau riverpod
  intl: (untuk formatting)
  uuid: (untuk unique IDs)
  cached_network_image: (for images)
```

---

## 📱 Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── ui/
│   ├── color.dart (color palette)
│   ├── typography.dart (text styles)
│   └── theme.dart
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── add_order/
│   │   ├── add_order_screen.dart
│   │   ├── models/ (order models)
│   │   └── widgets/ (reusable components)
│   ├── order_history/
│   ├── dashboard/
│   └── customer_management/
├── config/
│   └── firebase_config.dart
├── data/
│   ├── models/ (data models)
│   ├── services/ (API & Firestore services)
│   └── repositories/ (data layer)
├── models/ (shared models)
├── utility/ (helpers & utilities)
└── assets/
    ├── images/
    ├── fonts/
    └── svg/
```

---

## 🚀 Installation & Setup

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Firebase project setup
- Android Studio / Xcode for emulator

### Steps
1. Clone repository
   ```bash
   git clone https://github.com/your-username/laundriin.git
   cd laundriin
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase
   - Download `google-services.json` untuk Android
   - Download `GoogleService-Info.plist` untuk iOS
   - Place di masing-masing folder platform

4. Run app
   ```bash
   flutter run
   ```

---

## 📖 How to Use

### For Shop Owner:
1. **Sign up** dengan email & password
2. **Set pricing** di settings (harga per kilo, extra services)
3. **Add order** dengan klik tombol "Tambah Order"
4. **Fill customer info** (nama, gender, kontak)
5. **Choose service** (kategori, jenis, kecepatan)
6. **Review pricing** dan submit order
7. **Track orders** di history page

---

## 🤝 Contributing

Kontribusi sangat diterima! Untuk kontribusi:
1. Fork repository
2. Buat branch fitur (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📧 Contact & Support

- **Email**: support@laundriin.com
- **WhatsApp**: [Link WhatsApp]
- **Issues**: GitHub Issues

---

## 🎓 Academic Project

Laundriin dibuat sebagai Tugas Akhir (Final Project) untuk:
- Aplikasi mobile Flutter yang real-world
- Firebase integration
- Database design & management
- UI/UX implementation
- Business logic implementation
