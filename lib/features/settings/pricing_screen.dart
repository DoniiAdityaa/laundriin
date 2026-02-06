import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/utility/formatter/rupiah_formatter.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _pricePerKiloC = TextEditingController();
  final _expressSurchargeC = TextEditingController();
  final _ironingC = TextEditingController();
  final _dryWashC = TextEditingController();
  final _steamIroningC = TextEditingController();
  final _blankletC = TextEditingController();
  final _bedsheetC = TextEditingController();
  final _bedcoverC = TextEditingController();
  final _jacketC = TextEditingController();
  final _carpetC = TextEditingController();
  final _otherC = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _nonKiloItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Helper function untuk parse rupiah format ke int
  int _parseRupiahToInt(String text) {
    // Remove koma dan spasi: "6.000" atau "6,000" jadi "6000"
    String cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  // Helper function untuk format number dengan comma separator
  String _formatNumberWithComma(dynamic value) {
    int number = 0;
    if (value is int) {
      number = value;
    } else if (value is double) {
      number = value.toInt();
    } else if (value is String) {
      number = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    }

    if (number == 0) return '';

    // Format dengan comma separator (1000 -> "1.000")
    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  Future<void> _loadPricingData() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!['pricing'] ?? {};
        setState(() {
          // Format number dengan RupiahFormatter logic (add commas)
          _pricePerKiloC.text =
              _formatNumberWithComma(data['pricePerKilo'] ?? 0);
          _expressSurchargeC.text =
              _formatNumberWithComma(data['expressSurcharge'] ?? 0);
          _ironingC.text = _formatNumberWithComma(data['ironing'] ?? 0);
          _dryWashC.text = _formatNumberWithComma(data['dryWash'] ?? 0);
          _steamIroningC.text =
              _formatNumberWithComma(data['steamIroning'] ?? 0);
          _blankletC.text = _formatNumberWithComma(data['blanket'] ?? 0);
          _bedsheetC.text = _formatNumberWithComma(data['bedsheet'] ?? 0);
          _bedcoverC.text = _formatNumberWithComma(data['bedcover'] ?? 0);
          _jacketC.text = _formatNumberWithComma(data['jacket'] ?? 0);
          _carpetC.text = _formatNumberWithComma(data['smallCarpet'] ?? 0);
          _otherC.text = _formatNumberWithComma(data['other'] ?? 0);

          // Load non-kiloan items dari Firestore
          if (data['nonKiloItems'] != null) {
            _nonKiloItems = List<Map<String, dynamic>>.from(
              (data['nonKiloItems'] as List)
                  .map((item) => Map<String, dynamic>.from(item as Map)),
            );
            print('[LOAD] Loaded ${_nonKiloItems.length} items from Firestore');
          }
        });
      }
    } catch (e) {
      print('[ERROR] Loading pricing: $e');
    }
  }

  Future<void> _savePricingData() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(_userId).set(
        {
          'pricing': {
            'pricePerKilo': _parseRupiahToInt(_pricePerKiloC.text),
            'expressSurcharge': _parseRupiahToInt(_expressSurchargeC.text),
            'ironing': _parseRupiahToInt(_ironingC.text),
            'dryWash': _parseRupiahToInt(_dryWashC.text),
            'steamIroning': _parseRupiahToInt(_steamIroningC.text),
            'blanket': _parseRupiahToInt(_blankletC.text),
            'bedsheet': _parseRupiahToInt(_bedsheetC.text),
            'bedcover': _parseRupiahToInt(_bedcoverC.text),
            'jacket': _parseRupiahToInt(_jacketC.text),
            'smallCarpet': _parseRupiahToInt(_carpetC.text),
            'other': _parseRupiahToInt(_otherC.text),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga berhasil disimpan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pricePerKiloC.dispose();
    _expressSurchargeC.dispose();
    _ironingC.dispose();
    _dryWashC.dispose();
    _steamIroningC.dispose();
    _blankletC.dispose();
    _bedsheetC.dispose();
    _bedcoverC.dispose();
    _jacketC.dispose();
    _carpetC.dispose();
    _otherC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kiloInt = _parseRupiahToInt(_pricePerKiloC.text);
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              _buildHeader(
                  title: 'Pricing Settings',
                  subtitle: 'Manage kiloan and non-kiloan prices'),
              const SizedBox(height: 24),
              // ===== Kilogram Pricing =====
              _buildPricingCard(
                leadingIcon: Icons.attach_money_rounded,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFEFFDF2),
                title: "Kiloan Service",
                subtitle: "Weight-based pricing",
                label: "Price per Kilogram (Rp)",
                controller: _pricePerKiloC,
                currentText:
                    "Current: Rp ${_formatNumberWithComma(kiloInt)} per kg",
              ),
              const SizedBox(height: 24),
              // ===== Express Surcharge =====
              _buildPricingCard(
                leadingIcon: Icons.bolt_rounded,
                iconColor: const Color(0xFFCA8A04),
                bgColor: const Color(0xFFFEF9C3),
                title: "Express Service",
                subtitle: "Additional charge for rush service",
                label: "Express Surcharge (Rp)",
                controller: _expressSurchargeC,
                currentText:
                    "Additional: Rp ${_formatNumberWithComma(_parseRupiahToInt(_expressSurchargeC.text))}",
              ),
              const SizedBox(height: 24),
              // ===== Ironing =====
              _buildPricingCard(
                leadingIcon: Icons.local_laundry_service_rounded,
                iconColor: const Color(0xFF0891B2),
                bgColor: const Color(0xFFCFFAFE),
                title: "Ironing Service",
                subtitle: "Hanya setrika",
                label: "Price per Kilogram (Rp)",
                controller: _ironingC,
                currentText:
                    "Current: Rp ${_formatNumberWithComma(_parseRupiahToInt(_ironingC.text))} per kg",
              ),
              const SizedBox(height: 24),
              // ===== Dry Wash =====
              _buildPricingCard(
                leadingIcon: Icons.opacity_rounded,
                iconColor: const Color(0xFF06B6D4),
                bgColor: const Color(0xFFECFDF5),
                title: "Dry Wash Service",
                subtitle: "Hanya cuci (semi-kering)",
                label: "Price per Kilogram (Rp)",
                controller: _dryWashC,
                currentText:
                    "Current: Rp ${_formatNumberWithComma(_parseRupiahToInt(_dryWashC.text))} per kg",
              ),
              const SizedBox(height: 24),
              // ===== Steam Ironing =====
              _buildPricingCard(
                leadingIcon: Icons.cloud_rounded,
                iconColor: const Color(0xFFEC4899),
                bgColor: const Color(0xFFFCE7F3),
                title: "Steam Ironing Service",
                subtitle: "Setrika dengan uap",
                label: "Price per Kilogram (Rp)",
                controller: _steamIroningC,
                currentText:
                    "Current: Rp ${_formatNumberWithComma(_parseRupiahToInt(_steamIroningC.text))} per kg",
              ),
              const SizedBox(height: 24),
              _buildSatuanCard(
                  leadingIcon: Icons.attach_money_rounded,
                  title: 'Non-Kiloan Items',
                  subtitle: 'items-based',
                  label: 'a',
                  controller: _jacketC,
                  currentText: ''),

              const SizedBox(height: 32),

              // ===== Save Button =====
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: blue500.withOpacity(0.3),
                  ),
                  onPressed: _isLoading ? null : _savePricingData,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/svg/lets-icons_save.svg',
                              color: white,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Save All Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Custom Header (bukan AppBar)
  // =========================
  Widget _buildHeader({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(title, style: mBold),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: sRegular.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // Satuan Card UI
  // =========================
  Widget _buildSatuanCard({
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required String label,
    required TextEditingController controller,
    required String currentText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + title/subtitle + add button
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFDF2), // hijau muda halus
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  size: 34,
                  color: Color(0xFF16A34A), // hijau
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: mBold),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: sRegular,
                    ),
                  ],
                ),
              ),

              // Add button (+)
              InkWell(
                onTap: () => _add(
                  title: 'Tambah Item',
                  subtitle: 'Item yang tidak berasal dari kiloan',
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: borderLight),
          const SizedBox(height: 14),

          // List item cards - dari Firestore
          if (_nonKiloItems.isNotEmpty)
            ..._nonKiloItems.map((item) {
              // Handle price conversion - dari String/int/num ke int
              int price = 0;
              final priceValue = item['price'];
              if (priceValue is int) {
                price = priceValue;
              } else if (priceValue is double) {
                price = priceValue.toInt();
              } else if (priceValue is String) {
                price = int.tryParse(priceValue) ?? 0;
              }

              print(
                  '[DEBUG] Rendering item - name: ${item['name']}, price: $price (original: $priceValue)');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildNonKiloItem(
                  label: item['name']?.toString() ?? '',
                  controller: TextEditingController(text: price.toString()),
                  hintText: 'Rp $price',
                  onEdit: () => _add(
                    title: 'Edit Item',
                    subtitle: 'Update item non-kiloan',
                    initialName: item['name']?.toString() ?? '',
                    initialPrice: price.toString(),
                    itemId: item['id']?.toString(),
                    isEdit: true,
                  ),
                  onDelete: () async {
                    print('[DELETE] Removing item: ${item['name']}');
                    try {
                      // Hapus dari local list
                      setState(() {
                        _nonKiloItems.removeWhere((x) => x['id'] == item['id']);
                      });

                      // Simpan ke Firestore langsung
                      await _firestore.collection('users').doc(_userId).set(
                        {
                          'pricing': {
                            'nonKiloItems': _nonKiloItems,
                            'updatedAt': FieldValue.serverTimestamp(),
                          },
                        },
                        SetOptions(merge: true),
                      );

                      print('[SUCCESS] Item berhasil dihapus dari database');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item berhasil dihapus'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print('[ERROR] Gagal hapus item: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal hapus: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList()
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Belum ada item. Klik + untuk menambah.',
                  style: sRegular.copyWith(
                    color: const Color(0xFFB4B4B4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNonKiloItem({
    required String label,
    required TextEditingController controller,
    required String hintText,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard, // putih/soft
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: smBold),
                const SizedBox(height: 6),
                Text(
                  "Rp ${_formatNumberWithComma(controller.text.isEmpty ? 0 : int.tryParse(controller.text) ?? 0)}",
                  style: smMedium.copyWith(
                    color: green500,
                  ),
                ),
              ],
            ),
          ),

          // Edit
          IconButton(
            onPressed: onEdit,
            icon: SvgPicture.asset(
              'assets/svg/mingcute_pencil-line.svg',
              color: blue600,
            ),
          ),

          // Delete
          IconButton(
            onPressed: onDelete,
            icon: SvgPicture.asset(
              'assets/svg/mynaui_trash.svg',
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Pricing Card UI
  // =========================
  Widget _buildPricingCard({
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required String label,
    required TextEditingController controller,
    required String currentText,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon box + title/subtitle
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, size: 34, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: mBold,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: sRegular),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),
          Divider(color: borderLight),
          const SizedBox(height: 13),

          Text(
            label,
            style: smBold,
          ),
          const SizedBox(height: 10),

          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahFormatter(showRp: false)],
            style: smBold,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            currentText,
            style: xsRegular,
          ),
        ],
      ),
    );
  }

  void _add({
    required String title,
    required String subtitle,
    String initialName = "",
    String initialPrice = "",
    String? itemId,
    bool isEdit = false,
  }) {
    final nameC = TextEditingController(text: initialName);
    final priceC = TextEditingController(text: initialPrice);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: gray300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title + Subtitle
                Text(title, style: mBold),
                const SizedBox(height: 4),
                Text(subtitle, style: sRegular.copyWith(color: textSecondary)),
                const SizedBox(height: 18),

                // ===== Item Name =====
                Text("Item Name", style: smBold),
                const SizedBox(height: 8),
                TextField(
                  controller: nameC,
                  textCapitalization: TextCapitalization.words,
                  style: sBold.copyWith(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "e.g. Blanket",
                    hintStyle: sRegular.copyWith(color: textMuted),
                    filled: true,
                    fillColor: bgInput,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
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

                const SizedBox(height: 14),

                // ===== Price =====
                Text("Price (Rp)", style: smBold),
                const SizedBox(height: 8),
                TextField(
                  controller: priceC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahFormatter(showRp: false)],
                  style: sBold.copyWith(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "e.g. 25000",
                    hintStyle: sRegular.copyWith(color: textMuted),
                    filled: true,
                    fillColor: bgInput,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
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

                const SizedBox(height: 18),

                // ===== Save Button =====
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameC.text.trim();
                      final priceText = priceC.text.trim();
                      final price = _parseRupiahToInt(priceText);

                      if (name.isEmpty || priceText.isEmpty || price <= 0) {
                        print(
                            '[ERROR] Validasi gagal - name: $name, price: $price');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Item name & price wajib diisi"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        if (isEdit && itemId != null) {
                          print(
                              '[EDIT] Mengupdate item: $itemId - name: $name, price: $price');
                          final idx = _nonKiloItems
                              .indexWhere((x) => x['id'] == itemId);
                          if (idx != -1) {
                            setState(() {
                              _nonKiloItems[idx]['name'] = name;
                              _nonKiloItems[idx]['price'] = price;
                            });

                            // Simpan ke Firestore
                            await _firestore
                                .collection('users')
                                .doc(_userId)
                                .set(
                              {
                                'pricing': {
                                  'nonKiloItems': _nonKiloItems,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                },
                              },
                              SetOptions(merge: true),
                            );

                            print(
                                '[SUCCESS] Item berhasil diupdate di database');
                          }
                        } else {
                          print(
                              '[ADD] Menambah item baru - name: $name, price: $price');
                          final newItemId =
                              DateTime.now().millisecondsSinceEpoch.toString();

                          await _firestore.collection('users').doc(_userId).set(
                            {
                              'pricing': {
                                'nonKiloItems': FieldValue.arrayUnion([
                                  {
                                    'id': newItemId,
                                    'name': name,
                                    'price': price,
                                  },
                                ]),
                                'updatedAt': FieldValue.serverTimestamp(),
                              },
                            },
                            SetOptions(merge: true),
                          );

                          print(
                              '[SUCCESS] Item berhasil disimpan ke Firestore - ID: $newItemId, name: $name, price: $price');

                          setState(() {
                            _nonKiloItems.add({
                              'id': newItemId,
                              'name': name,
                              'price': price,
                            });
                          });
                        }

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit
                                ? 'Item berhasil diupdate'
                                : 'Item berhasil ditambah ke database'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        print('[ERROR] Gagal save item: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text("Save", style: smBold.copyWith(color: white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
