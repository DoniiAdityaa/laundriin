import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/utility/app_dialogs.dart';
import 'package:laundriin/utility/app_loading_overlay.dart';
import 'package:laundriin/utility/receipt_screen.dart';
import 'package:laundriin/config/shop_config.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  int _currentStep = 1; // Step 1: Customer Info

  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();

  String _selectedGender = 'Laki-laki'; // Default gender

  // Firestore & Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Customer search state
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSuggestions = false;
  String? _selectedCustomerId; // Track if customer is from database

  // ====== STEP 2: SERVICE ORDER STATE ======
  String _selectedCategory = 'Kiloan'; // Kiloan / Satuan / Campuran
  String _selectedServiceType =
      'washComplete'; // washComplete / ironing / dryWash / steamIroning
  String _selectedSpeed = 'Regular'; // Regular / Express
  final _weightC = TextEditingController(); // For Kiloan/Campuran
  final _qtyC = TextEditingController(); // For Satuan/Campuran
  final _notesC = TextEditingController(); // Special notes

  // Pricing from database
  int _pricePerKilo = 0;
  int _expressSurcharge = 0;
  int _ironingPrice = 0;
  int _dryWashPrice = 0;
  int _steamIroningPrice = 0;
  List<Map<String, dynamic>> _nonKiloanItems = [];
  Map<String, int> _nonKiloanSelectedItems = {}; // item id -> quantity

  // Track shop settings loading
  bool _shopSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameC.addListener(_onNameChanged);
    _loadPricingData();
    _loadShopSettings(); // Background load shop info dari Firestore
  }

  Future<void> _loadShopSettings() async {
    try {
      // Load shop info + delivery config dari database
      await ShopSettings.loadFromFirestore(_userId);
      await DeliveryConfig.loadFromDatabase(_userId); // Load express hours
      setState(() => _shopSettingsLoaded = true);
      print('[INIT] ✅ Shop settings & delivery config loaded successfully');
    } catch (e) {
      print('[ERROR] Failed to load settings: $e');
      setState(() => _shopSettingsLoaded = true);
    }
  }

  Future<void> _loadPricingData() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final pricing = doc.data()!['pricing'] ?? {};
        final nonKiloanList = pricing['nonKiloItems'] ?? [];

        setState(() {
          _pricePerKilo = pricing['pricePerKilo'] ?? 0;
          _expressSurcharge = pricing['expressSurcharge'] ?? 0;
          _ironingPrice = pricing['ironing'] ?? 0;
          _dryWashPrice = pricing['dryWash'] ?? 0;
          _steamIroningPrice = pricing['steamIroning'] ?? 0;
          _nonKiloanItems = List<Map<String, dynamic>>.from(nonKiloanList);
        });
        print(
            '[LOAD] Pricing: Wash=${_pricePerKilo}, Ironing=${_ironingPrice}, DryWash=${_dryWashPrice}, SteamIroning=${_steamIroningPrice}');
      }
    } catch (e) {
      print('[ERROR] Load pricing: $e');
    }
  }

  void _onNameChanged() {
    if (_nameC.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
        _selectedCustomerId = null;
      });
      return;
    }

    _searchCustomers(_nameC.text.trim());
  }

  Future<void> _searchCustomers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('customers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      setState(() {
        _searchResults = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _showSuggestions = _searchResults.isNotEmpty;
      });

      print(
          '[SEARCH] Found ${_searchResults.length} customers matching "$query"');
    } catch (e) {
      print('[ERROR] Search customers: $e');
    }
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _nameC.text = customer['name'] ?? '';
      _phoneC.text = customer['phone'] ?? '';
      _selectedGender = customer['gender'] ?? 'Laki-laki';
      _selectedCustomerId = customer['id'];
      _showSuggestions = false;
      _searchResults = [];
    });

    print(
        '[SELECT] Customer selected: ${customer['name']} (${customer['id']})');
  }

  void _clearCustomerSelection() {
    setState(() {
      _nameC.clear();
      _phoneC.clear();
      _selectedGender = 'Laki-laki';
      _selectedCustomerId = null;
      _showSuggestions = false;
      _searchResults = [];
    });

    print('[CLEAR] Customer selection cleared');
  }

  void _addNonKiloanItem(String itemId) {
    setState(() {
      if (_nonKiloanSelectedItems.containsKey(itemId)) {
        _nonKiloanSelectedItems[itemId] = _nonKiloanSelectedItems[itemId]! + 1;
      } else {
        _nonKiloanSelectedItems[itemId] = 1;
      }
    });
  }

  void _removeNonKiloanItem(String itemId) {
    setState(() {
      if (_nonKiloanSelectedItems.containsKey(itemId)) {
        _nonKiloanSelectedItems[itemId] = _nonKiloanSelectedItems[itemId]! - 1;
        if (_nonKiloanSelectedItems[itemId]! <= 0) {
          _nonKiloanSelectedItems.remove(itemId);
        }
      }
    });
  }

  Future<void> _saveNewCustomer() async {
    try {
      final customerId = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('customers')
          .doc()
          .id;

      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('customers')
          .doc(customerId)
          .set({
        'name': _nameC.text.trim(),
        'phone': _phoneC.text.trim(),
        'gender': _selectedGender,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _selectedCustomerId = customerId;
      print('[SAVE] New customer created: $_selectedCustomerId');
    } catch (e) {
      print('[ERROR] Save customer: $e');
      throw e;
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _weightC.dispose();
    _qtyC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep == 1) {
      // Validate step 1
      if (_nameC.text.trim().isEmpty || _phoneC.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama dan nomor HP wajib diisi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save new customer if not selected from database
      if (_selectedCustomerId == null) {
        try {
          await _saveNewCustomer();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal simpan pelanggan: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Move to step 2
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Validate step 2
      if (_selectedCategory == 'Kiloan' && _weightC.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berat harus diisi untuk kategori Kiloan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedCategory == 'Satuan' && _nonKiloanSelectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih minimal 1 item untuk kategori Satuan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedCategory == 'Campuran' &&
          (_weightC.text.trim().isEmpty && _nonKiloanSelectedItems.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Isi berat atau pilih item untuk kategori Campuran'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Move to step 3
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      // Create order and save to Firestore
      _createOrder();
    }
  }

  Future<void> _createOrder() async {
    if (!mounted) return;

    AppLoading.show(
      context,
      message: 'Membuat pesanan...',
    );

    try {
      print('═══════════════════════════════════════════════════════════');
      print('[CREATE ORDER] Starting order creation...');
      print('═══════════════════════════════════════════════════════════');

      if (_userId.isEmpty) {
        AppLoading.hide(context);
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Error'),
            content: Text('User belum login. Silakan login ulang.'),
          ),
        );
        return;
      }

      // Generate Order ID dengan format ORD-YYYY-MM-DD-XXXXXX
      final now = DateTime.now();
      final orderId =
          'ORD-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch % 1000000}';
      print('[ORDER ID] $orderId');

      // Prepare order data
      Map<String, dynamic> itemsData = {};
      _nonKiloanSelectedItems.forEach((itemId, qty) {
        final item = _nonKiloanItems.firstWhere(
          (item) => (item['id']?.toString() ?? '') == itemId,
          orElse: () => {'id': itemId, 'name': 'Unknown', 'price': 0},
        );
        itemsData[itemId] = {
          'name': item['name'],
          'qty': qty,
          'price': item['price'],
        };
      });

      if (itemsData.isNotEmpty) {
        print('[ITEMS DATA]');
        itemsData.forEach((key, value) {
          print(
              '  - $key: ${value['name']} x${value['qty']} @ Rp ${value['price']}');
        });
      } else {
        print('[ITEMS DATA] Kosong (kategori kiloan atau tidak ada items)');
      }

      final orderData = {
        'orderId': orderId,
        'customerId': _selectedCustomerId,
        'customerName': _nameC.text.trim(),
        'customerPhone': _phoneC.text.trim(),
        'customerGender': _selectedGender,
        'category': _selectedCategory.toLowerCase(),
        'serviceType': _selectedServiceType,
        'speed': _selectedSpeed.toLowerCase(),
        'weight': _selectedCategory == 'Kiloan' ||
                _selectedCategory == 'Campuran' &&
                    _weightC.text.trim().isNotEmpty
            ? int.tryParse(_weightC.text)
            : null,
        'items': itemsData.isEmpty ? null : itemsData,
        'totalPrice': _calculateTotalPrice(),
        'notes': _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Print order data for verification
      print('[ORDER DATA]');
      print('  - Order ID: $orderId');
      print(
          '  - Customer: ${orderData['customerName']} (${orderData['customerPhone']})');
      print('  - Customer ID: ${orderData['customerId']}');
      print('  - Category: ${orderData['category']}');
      print('  - Service Type: ${orderData['serviceType']}');
      print('  - Speed: ${orderData['speed']}');
      print('  - Weight: ${orderData['weight']} kg');
      print('  - Total Price: Rp ${orderData['totalPrice']}');
      print('  - Notes: ${orderData['notes'] ?? '(tidak ada)'}');
      print('  - Status: ${orderData['status']}');

      // Simulate network delay for better UX
      await Future.delayed(const Duration(milliseconds: 1500));

      // Save to Firestore dengan timeout 10 detik
      print('[FIREBASE] Saving to path: /shops/$_userId/orders/$orderId');
      print('[TIMEOUT] Setting timeout to 10 seconds...');

      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .doc(orderId)
          .set(orderData)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Firestore operation timeout - pastikan internet stabil',
          );
        },
      );

      print('[SUCCESS] ✅ Pesanan berhasil disimpan ke database!');
      print('═══════════════════════════════════════════════════════════');

      // Close loading dialog and show success dialog
      if (mounted) {
        AppLoading.hide(context);

        if (!mounted) return;

        // Show success dialog
        showSuccessOrderDialog(
          context,
          orderId: orderId,
          onViewReceipt: () {
            // Navigate to receipt page with order data
            print('[ACTION] View receipt: $orderId');
            Navigator.of(context).pop(); // Close dialog

            // Create receipt items list
            List<ReceiptItem> receiptItems = [];
            _nonKiloanSelectedItems.forEach((itemId, qty) {
              final item = _nonKiloanItems.firstWhere(
                (item) => (item['id']?.toString() ?? '') == itemId,
                orElse: () => {'name': 'Unknown', 'price': 0},
              );
              final itemPrice = item['price'] as int? ?? 0;
              receiptItems.add(
                ReceiptItem(
                  name: item['name'] ?? 'Unknown',
                  quantity: qty,
                  unit: 'item',
                  unitPrice: itemPrice,
                  totalPrice: itemPrice * qty,
                ),
              );
            });

            // Navigate to receipt screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReceiptScreen(
                  orderId: orderId,
                  customerName: _nameC.text,
                  customerPhone: _phoneC.text,
                  kasirName: ShopSettings.currentUserName,
                  orderDate: DateTime.now(),
                  estimasiSelesai: DeliveryConfig.calculateEstimatedCompletion(
                    DateTime.now(),
                    _selectedSpeed.toLowerCase() == 'express',
                  ),
                  category: _selectedCategory.toLowerCase(),
                  serviceType: _selectedServiceType,
                  speed: _selectedSpeed.toLowerCase(),
                  weight: int.tryParse(_weightC.text) ?? 0,
                  items: receiptItems,
                  totalPrice: _calculateTotalPrice(),
                  notes: _notesC.text.trim().isNotEmpty
                      ? _notesC.text.trim()
                      : null,
                  pricePerKilo: _pricePerKilo,
                  expressCharge: _expressSurcharge,
                ),
              ),
            );
          },
          onBackHome: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Pop add order screen
          },
        );
      }
    } catch (e) {
      print('[ERROR] ❌ Gagal membuat pesanan!');
      print('[ERROR] Exception: $e');
      print('[ERROR] Type: ${e.runtimeType}');
      print('[ERROR] StackTrace: ${StackTrace.current}');
      print('═══════════════════════════════════════════════════════════');

      if (mounted) {
        AppLoading.hide(context); // Close loading overlay

        String errorTitle = '❌ Gagal Membuat Pesanan';
        String errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';

        // Determine user-friendly error message based on exception type
        if (e.toString().contains('TimeoutException') ||
            e.toString().contains('timeout')) {
          errorTitle = '⏱️ Timeout - Koneksi Lambat';
          errorMessage = 'Koneksi ke server terlalu lama.\n\n'
              'Pastikan:\n'
              '• WiFi/Data aktif\n'
              '• Sinyal cukup kuat\n'
              '• Coba ulangi pesanan';
        } else if (e.toString().contains('Unable to resolve host') ||
            e.toString().contains('network unreachable') ||
            e.toString().contains('Connection refused')) {
          errorTitle = '🌐 Masalah Jaringan';
          errorMessage = 'Tidak bisa terhubung ke server.\n\n'
              'Periksa:\n'
              '• Aktifkan WiFi atau Data\n'
              '• Restart WiFi/Data\n'
              '• Coba lagi dalam 30 detik';
        } else if (e.toString().contains('permission denied') ||
            e.toString().contains('Permission denied')) {
          errorTitle = '🔒 Akses Ditolak';
          errorMessage =
              'Anda tidak memiliki izin untuk membuat pesanan.\n\nSilakan hubungi admin.';
        } else if (e.toString().contains('not found') ||
            e.toString().contains('Not found')) {
          errorTitle = '❓ Data Tidak Ditemukan';
          errorMessage =
              'Data toko atau pelanggan tidak ditemukan.\n\nSilakan periksa profil toko.';
        }

        // Show error dialog with user-friendly message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(errorTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Error:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontFamily: 'monospace',
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('TUTUP'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Retry creating order
                  _createOrder();
                },
                child: const Text('ULANGI'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              _buildHeader(),
              const SizedBox(height: 24),

              // ===== Step Content =====
              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),
              if (_currentStep == 3) _buildStep3(),

              const SizedBox(height: 32),

              // ===== Navigation Buttons =====
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Header =====
  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Order', style: mBold),
                const SizedBox(height: 6),
                SizedBox(
                  height: 20,
                  child: _buildStepIndicator(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== Step Indicator =====
  Widget _buildStepIndicator() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Row(
        children: [
          // Step 1
          _buildStepDot(1),
          Flexible(
            flex: 1,
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: _currentStep > 1 ? blue500 : const Color(0xFFE5E7EB),
            ),
          ),
          // Step 2
          _buildStepDot(2),
          Flexible(
            flex: 1,
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: _currentStep > 2 ? blue500 : const Color(0xFFE5E7EB),
            ),
          ),
          // Step 3
          _buildStepDot(3),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? blue500 : const Color(0xFFE5E7EB),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[500],
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // ===== Step 1: Customer Info =====
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informasi Pelanggan', style: mBold),
        const SizedBox(height: 4),
        Text(
          'Masukkan detail pelanggan untuk membuat pesanan',
          style: sRegular.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),

        // ===== Form Container =====
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Name Field with Autocomplete =====
              Text('Nama Pelanggan', style: smBold),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameC,
                    textCapitalization: TextCapitalization.words,
                    style: smBold.copyWith(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nama Pelanggan Anda',
                      hintStyle: sRegular.copyWith(color: textMuted),
                      filled: true,
                      fillColor: bgInput,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderFocus, width: 1.2),
                      ),
                    ),
                  ),

                  // Suggestions Dropdown - Only show jika belum ada customer dipilih
                  if (_showSuggestions &&
                      _searchResults.isNotEmpty &&
                      _selectedCustomerId == null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: borderLight,
                        ),
                        itemBuilder: (context, index) {
                          final customer = _searchResults[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              customer['name'] ?? '',
                              style: smBold.copyWith(color: textPrimary),
                            ),
                            subtitle: Text(
                              customer['phone'] ?? '',
                              style: xsRegular.copyWith(color: textMuted),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              iconSize: 20,
                              color: Colors.red[400],
                              onPressed: () => _clearCustomerSelection(),
                            ),
                            onTap: () => _selectCustomer(customer),
                          );
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // ===== Gender Field =====
              Text('Jenis Kelamin', style: smBold),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedGender = 'Laki-laki'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'Laki-laki'
                              ? blue500
                              : bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedGender == 'Laki-laki'
                                ? blue500
                                : borderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Laki-laki',
                            style: smBold.copyWith(
                              color: _selectedGender == 'Laki-laki'
                                  ? Colors.white
                                  : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedGender = 'Perempuan'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'Perempuan'
                              ? blue500
                              : bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedGender == 'Perempuan'
                                ? blue500
                                : borderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Perempuan',
                            style: smBold.copyWith(
                              color: _selectedGender == 'Perempuan'
                                  ? Colors.white
                                  : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ===== Phone Field =====
              Text('Nomor WhatsApp', style: smBold),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneC,
                keyboardType: TextInputType.phone,
                style: smBold.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  hintText: '081xxxx',
                  hintStyle: sRegular.copyWith(color: textMuted),
                  filled: true,
                  fillColor: bgInput,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixText: '+62 ',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderFocus, width: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Bottom Navigation Buttons =====
  Widget _buildBottomButtons() {
    String buttonLabel = 'Lanjut';
    if (_currentStep == 3) {
      buttonLabel = 'Buat Pesanan';
    }

    return Row(
      children: [
        // Back Button
        if (_currentStep > 1)
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderLight, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Kembali',
                  style: smBold.copyWith(color: textPrimary),
                ),
              ),
            ),
          ),

        if (_currentStep > 1) const SizedBox(width: 12),

        // Next/Continue Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: blue500.withOpacity(0.3),
              ),
              child: Text(
                buttonLabel,
                style: smBold.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ====== STEP 2: SERVICE ORDER ======
  Widget _buildStep2() {
    // Get selected service price
    int selectedServicePrice = _pricePerKilo; // default wash complete
    if (_selectedServiceType == 'ironing') {
      selectedServicePrice = _ironingPrice;
    } else if (_selectedServiceType == 'dryWash') {
      selectedServicePrice = _dryWashPrice;
    } else if (_selectedServiceType == 'steamIroning') {
      selectedServicePrice = _steamIroningPrice;
    }

    // Calculate price based on selections
    int basePrice = 0;
    if (_selectedCategory == 'Kiloan' && _weightC.text.isNotEmpty) {
      final weight = double.tryParse(_weightC.text) ?? 0;
      basePrice = (selectedServicePrice * weight).toInt();
    } else if (_selectedCategory == 'Satuan') {
      // Calculate total price for selected satuan items
      _nonKiloanSelectedItems.forEach((itemId, qty) {
        final item = _nonKiloanItems.firstWhere(
            (item) => (item['id']?.toString() ?? '') == itemId,
            orElse: () => {});
        if (item.isNotEmpty) {
          final itemPrice = item['price'] as int? ?? 0;
          basePrice += itemPrice * qty;
        }
      });
    } else if (_selectedCategory == 'Campuran') {
      // Calculate combined price: kiloan + satuan items
      // Kiloan part
      if (_weightC.text.isNotEmpty) {
        final weight = double.tryParse(_weightC.text) ?? 0;
        basePrice = (selectedServicePrice * weight).toInt();
      }
      // Satuan items part
      _nonKiloanSelectedItems.forEach((itemId, qty) {
        final item = _nonKiloanItems.firstWhere(
            (item) => (item['id']?.toString() ?? '') == itemId,
            orElse: () => {});
        if (item.isNotEmpty) {
          final itemPrice = item['price'] as int? ?? 0;
          basePrice += itemPrice * qty;
        }
      });
    }

    int expressPrice = (_selectedSpeed == 'Express') ? _expressSurcharge : 0;
    int totalPrice = basePrice + expressPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Jenis Pesanan', style: mBold),
        const SizedBox(height: 20),

        // ===== Category Selection =====
        Text('Kategori', style: smBold),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildCategoryButton('Kiloan'),
            const SizedBox(width: 12),
            _buildCategoryButton('Satuan'),
            const SizedBox(width: 12),
            _buildCategoryButton('Campuran'),
          ],
        ),
        const SizedBox(height: 20),

        // ===== Form Container Step 2 =====
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Service Type Selection (Kiloan only) =====
              if (_selectedCategory == 'Kiloan') ...[
                Text('Jenis Layanan', style: smBold),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceButton(
                            'washComplete',
                            'Komplit',
                            'Cuci + Setrika',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildServiceButton(
                            'ironing',
                            'Setrika',
                            'Hanya setrika',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceButton(
                            'dryWash',
                            'Kering',
                            'Hanya cuci',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildServiceButton(
                            'steamIroning',
                            'Uap',
                            'Setrika uap',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ===== Speed Selection =====
                Text('Kecepatan Layanan', style: smBold),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSpeed = 'Regular'),
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSpeed == 'Regular'
                                ? blue500.withOpacity(0.1)
                                : bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSpeed == 'Regular'
                                  ? blue500
                                  : borderLight,
                              width: _selectedSpeed == 'Regular' ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Regular',
                                  style: smBold.copyWith(
                                    color: _selectedSpeed == 'Regular'
                                        ? blue500
                                        : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSpeed = 'Express'),
                        child: Container(
                          height: 65,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSpeed == 'Express'
                                ? blue500.withOpacity(0.1)
                                : bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSpeed == 'Express'
                                  ? blue500
                                  : borderLight,
                              width: _selectedSpeed == 'Express' ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Express',
                                  style: smBold.copyWith(
                                    color: _selectedSpeed == 'Express'
                                        ? blue500
                                        : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+Rp ${_formatNumber(_expressSurcharge)}',
                                  style: xsRegular.copyWith(
                                    color: _selectedSpeed == 'Express'
                                        ? Colors.grey[400]
                                        : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // ===== Input based on Category =====
              if (_selectedCategory == 'Kiloan') ...[
                Text('Berat (kg)', style: smBold),
                const SizedBox(height: 8),
                TextField(
                  controller: _weightC,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: smBold.copyWith(color: textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '2',
                    hintStyle: sRegular.copyWith(color: textMuted),
                    filled: true,
                    fillColor: bgInput,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixText: 'kg',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderFocus, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text('Harga: Rp ${_formatNumber(selectedServicePrice)} per kg',
                    style: xsRegular.copyWith(color: textMuted)),
              ] else if (_selectedCategory == 'Satuan') ...[
                // ===== Speed Selection =====
                Text('Kecepatan Layanan', style: smBold),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSpeed = 'Regular'),
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSpeed == 'Regular'
                                ? blue500.withOpacity(0.1)
                                : bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSpeed == 'Regular'
                                  ? blue500
                                  : borderLight,
                              width: _selectedSpeed == 'Regular' ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Regular',
                                  style: smBold.copyWith(
                                    color: _selectedSpeed == 'Regular'
                                        ? blue500
                                        : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSpeed = 'Express'),
                        child: Container(
                          height: 65,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSpeed == 'Express'
                                ? blue500.withOpacity(0.1)
                                : bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSpeed == 'Express'
                                  ? blue500
                                  : borderLight,
                              width: _selectedSpeed == 'Express' ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Express',
                                  style: smBold.copyWith(
                                    color: _selectedSpeed == 'Express'
                                        ? blue500
                                        : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+Rp ${_formatNumber(_expressSurcharge)}',
                                  style: xsRegular.copyWith(
                                    color: _selectedSpeed == 'Express'
                                        ? Colors.grey[400]
                                        : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Pilih Item', style: smBold),
                const SizedBox(height: 8),
                if (_nonKiloanItems.isEmpty)
                  Text('Tidak ada item tersedia',
                      style: sRegular.copyWith(color: textMuted))
                else
                  Column(
                    children: _nonKiloanItems.map((item) {
                      final itemId = item['id']?.toString() ?? '';
                      final itemName = item['name'] ?? 'Unnamed';
                      final itemPrice = item['price'] as int? ?? 0;
                      final qty = _nonKiloanSelectedItems[itemId] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: qty > 0 ? Colors.blue[50] : bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: qty > 0 ? Colors.blue[300]! : borderLight,
                            width: qty > 0 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(itemName,
                                      style:
                                          smBold.copyWith(color: textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${_formatNumber(itemPrice)}',
                                    style: sRegular.copyWith(color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: qty > 0
                                      ? () => _removeNonKiloanItem(itemId)
                                      : null,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: qty > 0 ? blue500 : bgInput,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: qty > 0 ? blue500 : borderLight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color:
                                            qty > 0 ? Colors.white : textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 36,
                                  child: Center(
                                    child: Text(
                                      qty.toString(),
                                      style:
                                          smBold.copyWith(color: textPrimary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _addNonKiloanItem(itemId),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: blue500,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: blue500),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ] else ...[
                // Campuran
                // ===== Service Type Selection =====
                Text('Jenis Layanan', style: smBold),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceButton(
                            'washComplete',
                            'Komplit',
                            'Cuci + Setrika',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildServiceButton(
                            'ironing',
                            'Setrika',
                            'Hanya setrika',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildServiceButton(
                            'dryWash',
                            'Kering',
                            'Hanya cuci',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildServiceButton(
                            'steamIroning',
                            'Uap',
                            'Setrika uap',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ===== Speed Selection =====
                Text('Kecepatan Layanan', style: smBold),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSpeed = 'Regular'),
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSpeed == 'Regular'
                                ? blue500.withOpacity(0.1)
                                : bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSpeed == 'Regular'
                                  ? blue500
                                  : borderLight,
                              width: _selectedSpeed == 'Regular' ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Regular',
                                  style: smBold.copyWith(
                                    color: _selectedSpeed == 'Regular'
                                        ? blue500
                                        : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSpeed = 'Express'),
                        child: Container(
                          height: 65,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSpeed == 'Express'
                                ? blue500.withOpacity(0.1)
                                : bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSpeed == 'Express'
                                  ? blue500
                                  : borderLight,
                              width: _selectedSpeed == 'Express' ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Express',
                                  style: smBold.copyWith(
                                    color: _selectedSpeed == 'Express'
                                        ? blue500
                                        : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+Rp ${_formatNumber(_expressSurcharge)}',
                                  style: xsRegular.copyWith(
                                    color: _selectedSpeed == 'Express'
                                        ? Colors.grey[400]
                                        : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ===== Weight Input =====
                Text('Berat (kg)', style: smBold),
                const SizedBox(height: 8),
                TextField(
                  controller: _weightC,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: smBold.copyWith(color: textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '2',
                    hintStyle: sRegular.copyWith(color: textMuted),
                    filled: true,
                    fillColor: bgInput,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixText: 'kg',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderFocus, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text('Harga: Rp ${_formatNumber(selectedServicePrice)} per kg',
                    style: xsRegular.copyWith(color: textMuted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ===== Items Selection (For Campuran only) =====
        if (_selectedCategory == 'Campuran')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Item Satuan', style: smBold),
                const SizedBox(height: 12),
                if (_nonKiloanItems.isEmpty)
                  Text('Tidak ada item tersedia',
                      style: sRegular.copyWith(color: textMuted))
                else
                  Column(
                    children: _nonKiloanItems.map((item) {
                      final itemId = item['id']?.toString() ?? '';
                      final itemName = item['name'] ?? 'Unnamed';
                      final itemPrice = item['price'] as int? ?? 0;
                      final qty = _nonKiloanSelectedItems[itemId] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: qty > 0 ? Colors.blue[50] : bgInput,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: qty > 0 ? Colors.blue[300]! : borderLight,
                            width: qty > 0 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(itemName,
                                      style:
                                          smBold.copyWith(color: textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${_formatNumber(itemPrice)}',
                                    style: sRegular.copyWith(color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: qty > 0
                                      ? () => _removeNonKiloanItem(itemId)
                                      : null,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: qty > 0 ? blue500 : bgInput,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: qty > 0 ? blue500 : borderLight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color:
                                            qty > 0 ? Colors.white : textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 36,
                                  child: Center(
                                    child: Text(
                                      qty.toString(),
                                      style:
                                          smBold.copyWith(color: textPrimary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _addNonKiloanItem(itemId),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: blue500,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: blue500),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // ===== Special Notes =====
        Text('Catatan Khusus (Opsional)', style: smBold),
        const SizedBox(height: 8),
        TextField(
          controller: _notesC,
          maxLines: 3,
          style: sRegular.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Gunakan deterjen lembut, jangan putar kering...',
            hintStyle: sRegular.copyWith(color: textMuted),
            filled: true,
            fillColor: bgInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.blue[200]!, width: 1.2),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ===== Price Summary =====
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ringkasan Harga', style: smBold),
              const SizedBox(height: 12),

              // For Campuran, show breakdown
              if (_selectedCategory == 'Campuran') ...[
                // Kiloan part
                if (_weightC.text.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harga Kiloan:',
                        style: sRegular.copyWith(color: textSecondary),
                      ),
                      Text(
                        'Rp ${_formatNumber((selectedServicePrice * (double.tryParse(_weightC.text) ?? 0)).toInt())}',
                        style: smBold.copyWith(color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Satuan part
                if (_nonKiloanSelectedItems.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harga Satuan:',
                        style: sRegular.copyWith(color: textSecondary),
                      ),
                      Text(
                        'Rp ${_formatNumber(_calculateSatuanPrice())}',
                        style: smBold.copyWith(color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ] else ...[
                // Default: Show base price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Harga Dasar:',
                      style: sRegular.copyWith(color: textSecondary),
                    ),
                    Text(
                      'Rp ${_formatNumber(basePrice)}',
                      style: smBold.copyWith(color: textPrimary),
                    ),
                  ],
                ),
              ],

              if (_selectedSpeed == 'Express') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biaya Express:',
                      style: sRegular.copyWith(color: textSecondary),
                    ),
                    Text(
                      '+Rp ${_formatNumber(expressPrice)}',
                      style: smBold.copyWith(color: Colors.orange[700]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: borderLight),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: mBold,
                  ),
                  Text(
                    'Rp ${_formatNumber(totalPrice)}',
                    style: mBold.copyWith(color: blue500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Step 3: Order Confirmation =====
  Widget _buildStep3() {
    String categoryLabel = _selectedCategory == 'Kiloan'
        ? 'Kiloan'
        : _selectedCategory == 'Satuan'
            ? 'Satuan'
            : 'Campuran';

    // Determine service price based on selected service type
    int servicePrice = _pricePerKilo; // default wash complete
    if (_selectedServiceType == 'ironing') {
      servicePrice = _ironingPrice;
    } else if (_selectedServiceType == 'dryWash') {
      servicePrice = _dryWashPrice;
    } else if (_selectedServiceType == 'steamIroning') {
      servicePrice = _steamIroningPrice;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Title =====
          Text('Ringkasan Pesanan', style: mBold),
          const SizedBox(height: 4),
          Text(
            'Periksa detail pesanan sebelum membuat order',
            style: sRegular.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),

          // ===== SECTION 1: Customer Info =====
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue[200]!, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: blue500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/bust_in_silhouette.png',
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pelanggan',
                      style: mBold.copyWith(color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: borderLight, height: 1),
                const SizedBox(height: 16),
                // Customer details in rows
                _buildSummaryRow(
                    'Nama', _nameC.text.isNotEmpty ? _nameC.text : '-'),
                const SizedBox(height: 12),
                _buildSummaryRow('Jenis Kelamin',
                    _selectedGender.isNotEmpty ? _selectedGender : '-'),
                const SizedBox(height: 12),
                _buildSummaryRow(
                    'WhatsApp', _phoneC.text.isNotEmpty ? _phoneC.text : '-'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ===== SECTION 2: Order Details + Price Breakdown (REDESIGNED) =====
          _buildDetailPesananSection(
            categoryLabel,
            servicePrice,
          ),
          const SizedBox(height: 20),

          // ===== SECTION 3: Notes (Only if not empty) =====
          if (_notesC.text.trim().isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue[200]!, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.note_outlined,
                            color: Colors.orange[600],
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Catatan Khusus',
                        style: mBold.copyWith(color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderLight, height: 1),
                  const SizedBox(height: 16),
                  // Notes content
                  Text(
                    _notesC.text,
                    style: sRegular.copyWith(color: textPrimary),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Helper: Build summary row with label and value
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: sRegular.copyWith(color: textMuted),
        ),
        Text(
          value,
          style: smBold.copyWith(color: textPrimary),
        ),
      ],
    );
  }

  // Helper: Build detail item for order summary (user-friendly format)
  // Helper method to calculate total price
  int _calculateTotalPrice() {
    int total = 0;

    // Determine service price based on selected service type
    int servicePrice = _pricePerKilo; // default wash complete
    if (_selectedServiceType == 'ironing') {
      servicePrice = _ironingPrice;
    } else if (_selectedServiceType == 'dryWash') {
      servicePrice = _dryWashPrice;
    } else if (_selectedServiceType == 'steamIroning') {
      servicePrice = _steamIroningPrice;
    }

    if (_selectedCategory == 'Kiloan') {
      int weight = int.tryParse(_weightC.text) ?? 0;
      // Semua service type (Komplit, Setrika, Kering, Uap) gunakan service price per kg
      total = servicePrice * weight;

      // Hanya Express yang menambah harga
      if (_selectedSpeed == 'Express') total += _expressSurcharge;
    } else if (_selectedCategory == 'Satuan') {
      total = _calculateSatuanPrice();

      if (_selectedSpeed == 'Express') total += _expressSurcharge;
    } else if (_selectedCategory == 'Campuran') {
      int weight = int.tryParse(_weightC.text) ?? 0;
      total = servicePrice * weight;
      total += _calculateSatuanPrice();

      if (_selectedSpeed == 'Express') total += _expressSurcharge;
    }

    return total;
  }

  // ===== Helper: Service Type Button =====
  Widget _buildServiceButton(
    String serviceId,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedServiceType == serviceId;

    return GestureDetector(
      onTap: () => setState(() => _selectedServiceType = serviceId),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? blue500.withOpacity(0.1) : bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? blue500 : borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: smBold.copyWith(
                color: isSelected ? blue500 : textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: xsRegular.copyWith(
                color: isSelected ? Colors.grey[400] : textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helper: Category Button with Image =====
  Widget _buildCategoryButton(String category) {
    final isSelected = _selectedCategory == category;

    // Map category ke image path
    final imageMap = {
      'Kiloan': 'assets/images/Balance_Scale.png',
      'Satuan': 'assets/images/shirt.png',
      'Campuran': 'assets/images/package.png',
    };

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          width: double.infinity,
          height: 125, // Lebih besar untuk semua sama
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? blue500.withOpacity(0.1) : bgInput,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? blue500 : borderLight,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              Image.asset(
                imageMap[category]!,
                height: 40,
                width: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              // Text
              Text(
                category,
                textAlign: TextAlign.center,
                style: sBold.copyWith(
                  color: isSelected ? blue500 : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Helper: Build Detail Pesanan Section (Redesigned) =====
  Widget _buildDetailPesananSection(String categoryLabel, int servicePrice) {
    // Map category to image path
    final categoryImageMap = {
      'Kiloan': 'assets/images/Balance_Scale.png',
      'Satuan': 'assets/images/shirt.png',
      'Campuran': 'assets/images/package.png',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue[200]!, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: blue500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/basket.png',
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Detail Pesanan',
                style: mBold.copyWith(color: textPrimary),
              ),
            ],
          ),

          // ===== DIVIDER =====
          const SizedBox(height: 16),
          Divider(color: borderLight, height: 1),
          const SizedBox(height: 16),
          // ===== MODE =====
          Row(
            children: [
              Text(
                'Mode: ',
                style: sRegular.copyWith(color: textMuted),
              ),
              Image.asset(
                categoryImageMap[_selectedCategory] ??
                    'assets/images/package.png',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 6),
              Text(
                categoryLabel,
                style: sBold.copyWith(color: blue500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== ITEM SECTION =====
          Text(
            'ITEM',
            style: sBold.copyWith(
              color: textMuted,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Items based on category
          if (_selectedCategory == 'Kiloan') ...[
            _buildDetailPesananItem(
              label: _selectedServiceType == 'washComplete'
                  ? 'Cuci Komplit'
                  : _selectedServiceType == 'ironing'
                      ? 'Setrika'
                      : _selectedServiceType == 'dryWash'
                          ? 'Cuci Kering'
                          : 'Uap',
              quantity: _weightC.text.isEmpty ? '0' : _weightC.text,
              unit: 'Kg',
              unitPrice: servicePrice,
            ),
          ] else if (_selectedCategory == 'Satuan') ...[
            ..._nonKiloanSelectedItems.entries.map((entry) {
              final item = _nonKiloanItems.firstWhere(
                (item) => (item['id']?.toString() ?? '') == entry.key,
                orElse: () => {'name': 'Unknown', 'price': 0},
              );
              int price = item['price'] as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDetailPesananItem(
                  label: item['name'] ?? 'Unknown',
                  quantity: entry.value.toString(),
                  unit: 'item',
                  unitPrice: price,
                ),
              );
            }).toList(),
          ] else if (_selectedCategory == 'Campuran') ...[
            // Kiloan part
            _buildDetailPesananItem(
              label: (_selectedServiceType == 'washComplete'
                      ? 'Cuci Komplit'
                      : _selectedServiceType == 'ironing'
                          ? 'Setrika'
                          : _selectedServiceType == 'dryWash'
                              ? 'Cuci Kering'
                              : 'Uap') +
                  ' (Kiloan)',
              quantity: _weightC.text.isEmpty ? '0' : _weightC.text,
              unit: 'Kg',
              unitPrice: servicePrice,
            ),
            const SizedBox(height: 10),
            // Items part
            ..._nonKiloanSelectedItems.entries.map((entry) {
              final item = _nonKiloanItems.firstWhere(
                (item) => (item['id']?.toString() ?? '') == entry.key,
                orElse: () => {'name': 'Unknown', 'price': 0},
              );
              int price = item['price'] as int;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDetailPesananItem(
                  label: item['name'] ?? 'Unknown',
                  quantity: entry.value.toString(),
                  unit: 'item',
                  unitPrice: price,
                ),
              );
            }).toList(),
          ],

          // ===== BIAYA TAMBAHAN SECTION =====
          if (_selectedSpeed == 'Express') ...[
            const SizedBox(height: 16),
            Text(
              'BIAYA TAMBAHAN',
              style: sRegular.copyWith(
                color: textMuted,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailPesananItem(
              label: 'Express',
              quantity: '1',
              unit: 'order',
              unitPrice: _expressSurcharge,
              isAddOn: true,
            ),
          ],

          // ===== DIVIDER =====
          const SizedBox(height: 16),
          Divider(color: borderLight, height: 1),
          const SizedBox(height: 16),

          // ===== TOTAL =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: mBold.copyWith(color: textPrimary, fontSize: 14),
              ),
              Text(
                'Rp ${_formatNumber(_calculateTotalPrice())}',
                style: mBold.copyWith(color: blue500, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== Helper: Detail Pesanan Item =====
  Widget _buildDetailPesananItem({
    required String label,
    required String quantity,
    required String unit,
    required int unitPrice,
    bool isAddOn = false,
  }) {
    double qty = double.tryParse(quantity) ?? 1;
    int totalPrice = (unitPrice * qty).toInt();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: sRegular.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rp ${_formatNumber(unitPrice)} x $quantity',
                style: xsRegular.copyWith(color: textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Rp ${_formatNumber(totalPrice)}',
          style: sBold.copyWith(
            color: isAddOn ? Colors.orange[700] : blue500,
          ),
        ),
      ],
    );
  }

  // ===== Helper: Calculate Satuan Items Price =====
  int _calculateSatuanPrice() {
    int price = 0;
    _nonKiloanSelectedItems.forEach((itemId, qty) {
      final item = _nonKiloanItems.firstWhere(
          (item) => (item['id']?.toString() ?? '') == itemId,
          orElse: () => {});
      if (item.isNotEmpty) {
        final itemPrice = item['price'] as int? ?? 0;
        price += itemPrice * qty;
      }
    });
    return price;
  }

  // ===== Helper: Format Number =====
  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }
}
