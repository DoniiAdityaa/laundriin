import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/utility/formatter/rupiah_formatter.dart';
import 'package:laundriin/config/shop_config.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _komplitRegularPriceC = TextEditingController();
  final _komplitRegularHoursC = TextEditingController();
  final _komplitExpressPriceC = TextEditingController();
  final _komplitExpressHoursC = TextEditingController();

  final _setrikaRegularPriceC = TextEditingController();
  final _setrikaRegularHoursC = TextEditingController();
  final _setrikaExpressPriceC = TextEditingController();
  final _setrikaExpressHoursC = TextEditingController();

  final _keringRegularPriceC = TextEditingController();
  final _keringRegularHoursC = TextEditingController();
  final _keringExpressPriceC = TextEditingController();
  final _keringExpressHoursC = TextEditingController();

  final _karpetRegularPriceC = TextEditingController();
  final _karpetRegularHoursC = TextEditingController();
  final _karpetExpressPriceC = TextEditingController();
  final _karpetExpressHoursC = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Map<String, dynamic>> _nonKiloItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _userId => ShopSettings.shopOwnerId;

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
          _komplitRegularPriceC.text = _formatNumberWithComma(data['komplitRegularPrice'] ?? 0);
          _komplitRegularHoursC.text = (data['komplitRegularHours'] ?? 48).toString();
          _komplitExpressPriceC.text = _formatNumberWithComma(data['komplitExpressPrice'] ?? 0);
          _komplitExpressHoursC.text = (data['komplitExpressHours'] ?? 24).toString();

          _setrikaRegularPriceC.text = _formatNumberWithComma(data['setrikaRegularPrice'] ?? 0);
          _setrikaRegularHoursC.text = (data['setrikaRegularHours'] ?? 48).toString();
          _setrikaExpressPriceC.text = _formatNumberWithComma(data['setrikaExpressPrice'] ?? 0);
          _setrikaExpressHoursC.text = (data['setrikaExpressHours'] ?? 24).toString();

          _keringRegularPriceC.text = _formatNumberWithComma(data['keringRegularPrice'] ?? 0);
          _keringRegularHoursC.text = (data['keringRegularHours'] ?? 48).toString();
          _keringExpressPriceC.text = _formatNumberWithComma(data['keringExpressPrice'] ?? 0);
          _keringExpressHoursC.text = (data['keringExpressHours'] ?? 24).toString();

          _karpetRegularPriceC.text = _formatNumberWithComma(data['karpetRegularPrice'] ?? 0);
          _karpetRegularHoursC.text = (data['karpetRegularHours'] ?? 48).toString();
          _karpetExpressPriceC.text = _formatNumberWithComma(data['karpetExpressPrice'] ?? 0);
          _karpetExpressHoursC.text = (data['karpetExpressHours'] ?? 24).toString();
          _isLoadingData = false;

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
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _savePricingData() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(_userId).set(
        {
          'pricing': {
            'komplitRegularPrice': _parseRupiahToInt(_komplitRegularPriceC.text),
            'komplitRegularHours': int.tryParse(_komplitRegularHoursC.text) ?? 48,
            'komplitExpressPrice': _parseRupiahToInt(_komplitExpressPriceC.text),
            'komplitExpressHours': int.tryParse(_komplitExpressHoursC.text) ?? 24,
            
            'setrikaRegularPrice': _parseRupiahToInt(_setrikaRegularPriceC.text),
            'setrikaRegularHours': int.tryParse(_setrikaRegularHoursC.text) ?? 48,
            'setrikaExpressPrice': _parseRupiahToInt(_setrikaExpressPriceC.text),
            'setrikaExpressHours': int.tryParse(_setrikaExpressHoursC.text) ?? 24,
            
            'keringRegularPrice': _parseRupiahToInt(_keringRegularPriceC.text),
            'keringRegularHours': int.tryParse(_keringRegularHoursC.text) ?? 48,
            'keringExpressPrice': _parseRupiahToInt(_keringExpressPriceC.text),
            'keringExpressHours': int.tryParse(_keringExpressHoursC.text) ?? 24,
            
            'karpetRegularPrice': _parseRupiahToInt(_karpetRegularPriceC.text),
            'karpetRegularHours': int.tryParse(_karpetRegularHoursC.text) ?? 48,
            'karpetExpressPrice': _parseRupiahToInt(_karpetExpressPriceC.text),
            'karpetExpressHours': int.tryParse(_karpetExpressHoursC.text) ?? 24,
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
          content: Text('Kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _komplitRegularPriceC.dispose();
    _komplitRegularHoursC.dispose();
    _komplitExpressPriceC.dispose();
    _komplitExpressHoursC.dispose();

    _setrikaRegularPriceC.dispose();
    _setrikaRegularHoursC.dispose();
    _setrikaExpressPriceC.dispose();
    _setrikaExpressHoursC.dispose();

    _keringRegularPriceC.dispose();
    _keringRegularHoursC.dispose();
    _keringExpressPriceC.dispose();
    _keringExpressHoursC.dispose();

    _karpetRegularPriceC.dispose();
    _karpetRegularHoursC.dispose();
    _karpetExpressPriceC.dispose();
    _karpetExpressHoursC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: _buildHeader(
              title: 'Pengaturan Harga',
              subtitle: 'Kelola harga kiloan dan non-kiloan'),
        ),
      ),
      body: SafeArea(
        child: (_isLoading || _isLoadingData)
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // ===== Layanan Komplit =====
                    _buildServiceCard(
                      leadingIcon: Icons.local_laundry_service_rounded,
                      title: "Layanan Komplit",
                      subtitle: "Cuci dan Setrika",
                      bgColor: blue100,
                      iconColor: blue500,
                      regPriceC: _komplitRegularPriceC,
                      regHoursC: _komplitRegularHoursC,
                      expPriceC: _komplitExpressPriceC,
                      expHoursC: _komplitExpressHoursC,
                    ),
                    const SizedBox(height: 24),
                    // ===== Layanan Setrika =====
                    _buildServiceCard(
                      leadingIcon: Icons.iron_rounded,
                      title: "Layanan Setrika",
                      subtitle: "Hanya Setrika",
                      bgColor: blue100,
                      iconColor: blue500,
                      regPriceC: _setrikaRegularPriceC,
                      regHoursC: _setrikaRegularHoursC,
                      expPriceC: _setrikaExpressPriceC,
                      expHoursC: _setrikaExpressHoursC,
                    ),
                    const SizedBox(height: 24),
                    // ===== Layanan Cuci Kering =====
                    _buildServiceCard(
                      leadingIcon: Icons.opacity_rounded,
                      title: "Layanan Cuci Kering",
                      subtitle: "Hanya cuci (semi-kering)",
                      bgColor: blue100,
                      iconColor: blue500,
                      regPriceC: _keringRegularPriceC,
                      regHoursC: _keringRegularHoursC,
                      expPriceC: _keringExpressPriceC,
                      expHoursC: _keringExpressHoursC,
                    ),
                    const SizedBox(height: 24),
                    // ===== Layanan Karpet =====
                    _buildServiceCard(
                      leadingIcon: Icons.layers_rounded,
                      title: "Layanan Karpet",
                      subtitle: "Cuci Karpet",
                      bgColor: blue100,
                      iconColor: blue500,
                      regPriceC: _karpetRegularPriceC,
                      regHoursC: _karpetRegularHoursC,
                      expPriceC: _karpetExpressPriceC,
                      expHoursC: _karpetExpressHoursC,
                    ),
                    const SizedBox(height: 24),
                    _buildSatuanCard(
                        leadingIcon: Icons.attach_money_rounded,
                        title: 'Item Non-Kiloan',
                        subtitle: 'berbasis item'),

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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
                                    'Simpan Semua Perubahan',
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
                  color: blue100, // hijau muda halus
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  size: 34,
                  color: blue500, // hijau
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
                    title: 'Ubah Item',
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
            })
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
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: borderLight,
            width: 1,
          )),
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
  // Reusable Service Card UI
  // =========================
  Widget _buildServiceCard({
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required TextEditingController regPriceC,
    required TextEditingController regHoursC,
    required TextEditingController expPriceC,
    required TextEditingController expHoursC,
  }) {
    final regPrice = _parseRupiahToInt(regPriceC.text);
    final regHours = int.tryParse(regHoursC.text) ?? 48;
    final expPrice = _parseRupiahToInt(expPriceC.text);
    final expHours = int.tryParse(expHoursC.text) ?? 24;

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
          // Header
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
                    Text(title, style: mBold),
                    const SizedBox(height: 4),
                    Text(subtitle, style: sRegular),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== LAYANAN REGULAR =====
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 18, color: blue500),
                    const SizedBox(width: 8),
                    Text('Regular', style: smBold.copyWith(color: blue500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga /kg', style: xsBold),
                          const SizedBox(height: 6),
                          TextField(
                            controller: regPriceC,
                            keyboardType: TextInputType.number,
                            inputFormatters: [RupiahFormatter(showRp: false)],
                            style: sBold,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: white,
                              prefixText: 'Rp ',
                              prefixStyle: sBold,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderFocus, width: 1.2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Saat ini: Rp ${_formatNumberWithComma(regPrice)}', style: TextStyle(fontSize: 10, color: textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimasi (Jam)', style: xsBold),
                          const SizedBox(height: 6),
                          TextField(
                            controller: regHoursC,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: sBold,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: white,
                              suffixText: 'jam',
                              suffixStyle: sRegular.copyWith(color: textSecondary),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderFocus, width: 1.2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('(~${(regHours / 24).toStringAsFixed(1)} hari)', style: TextStyle(fontSize: 10, color: textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ===== LAYANAN EXPRESS =====
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text('Express', style: smBold.copyWith(color: Colors.orange.shade700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga /kg', style: xsBold),
                          const SizedBox(height: 6),
                          TextField(
                            controller: expPriceC,
                            keyboardType: TextInputType.number,
                            inputFormatters: [RupiahFormatter(showRp: false)],
                            style: sBold,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: white,
                              prefixText: 'Rp ',
                              prefixStyle: sBold,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.orange.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.orange.shade400, width: 1.2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Saat ini: Rp ${_formatNumberWithComma(expPrice)}', style: TextStyle(fontSize: 10, color: textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimasi (Jam)', style: xsBold),
                          const SizedBox(height: 6),
                          TextField(
                            controller: expHoursC,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: sBold,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: white,
                              suffixText: 'jam',
                              suffixStyle: sRegular.copyWith(color: textSecondary),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.orange.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.orange.shade400, width: 1.2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('(~${(expHours / 24).toStringAsFixed(1)} hari)', style: TextStyle(fontSize: 10, color: textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                Text("Nama Item", style: smBold),
                const SizedBox(height: 8),
                TextField(
                  controller: nameC,
                  textCapitalization: TextCapitalization.words,
                  style: sBold.copyWith(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "Contoh: Selimut",
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
                Text("Harga (Rp)", style: smBold),
                const SizedBox(height: 8),
                TextField(
                  controller: priceC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahFormatter(showRp: false)],
                  style: sBold.copyWith(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: "Contoh: 25000",
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
                    child: Text("Simpan", style: smBold.copyWith(color: white)),
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
