import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class ShopInformation extends StatefulWidget {
  const ShopInformation({super.key});

  @override
  State<ShopInformation> createState() => _ShopInformationState();
}

class _ShopInformationState extends State<ShopInformation> {
  final _shopNameC = TextEditingController();
  final _ownerNameC = TextEditingController();
  final _whatsappC = TextEditingController();
  final _addressC = TextEditingController();

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!['shopInfo'] ?? {};
        // Hapus 0 di depan saat load untuk display (karena prefix +62 sudah ada)
        String whatsapp = data['whatsapp'] ?? '';
        if (whatsapp.startsWith('0')) {
          whatsapp = whatsapp.substring(1);
        }

        setState(() {
          _shopNameC.text = data['shopName'] ?? '';
          _ownerNameC.text = data['ownerName'] ?? '';
          _whatsappC.text = whatsapp;
          _addressC.text = data['address'] ?? '';
        });
        print('[LOAD] Shop information loaded');
      }
    } catch (e) {
      print('[ERROR] Loading shop info: $e');
    }
  }

  Future<void> _saveShopData() async {
    setState(() => _isLoading = true);
    try {
      // Tambahkan 0 di depan saat simpan ke database (format lokal)
      String whatsapp = _whatsappC.text.trim();
      if (whatsapp.isNotEmpty && !whatsapp.startsWith('0')) {
        whatsapp = '0$whatsapp';
      }

      await _firestore.collection('users').doc(_userId).set(
        {
          'shopInfo': {
            'shopName': _shopNameC.text.trim(),
            'ownerName': _ownerNameC.text.trim(),
            'whatsapp': whatsapp,
            'address': _addressC.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop information berhasil disimpan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      print('[SUCCESS] Shop information saved to database');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('[ERROR] Saving shop info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _shopNameC.dispose();
    _ownerNameC.dispose();
    _whatsappC.dispose();
    _addressC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ===== Header =====
            _buildHeader(
                title: 'Informasi Toko',
                subtitle: 'Kelola informasi toko Anda'),
            const SizedBox(height: 24),
            _buildCardShop(),
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
                onPressed: _isLoading ? null : _saveShopData,
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
                          const SizedBox(width: 8),
                          Text(
                            'Simpan Perubahan',
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
          ]),
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
  // Shop Information Card
  // =========================
  Widget _buildCardShop() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row: icon + title/subtitle
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.store_rounded,
              size: 22,
              color: blue600,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informasi Toko', style: smSemiBold),
                const SizedBox(height: 4),
                Text(
                  'Detail tentang toko laundry Anda',
                  style: xsRegular,
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Divider(color: borderLight),
        const SizedBox(height: 16),

        // ===== Shop Name =====
        Text("Nama Toko", style: smBold),
        const SizedBox(height: 8),
        TextField(
          controller: _shopNameC,
          textCapitalization: TextCapitalization.words,
          style: sRegular.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: "e.g. Laundriin Express",
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

        const SizedBox(height: 16),

        // ===== Owner Name =====
        Text("Nama Pemilik", style: smBold),
        const SizedBox(height: 8),
        TextField(
          controller: _ownerNameC,
          textCapitalization: TextCapitalization.words,
          style: sRegular.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: "e.g. Budi Santoso",
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

        const SizedBox(height: 16),

        // ===== WhatsApp =====
        Text("Nomor WhatsApp", style: smBold),
        const SizedBox(height: 8),
        TextField(
          controller: _whatsappC,
          keyboardType: TextInputType.phone,
          style: sRegular.copyWith(color: textPrimary),
          onChanged: (value) {
            // Hapus 0 di depan otomatis karena prefix sudah +62
            if (value.startsWith('0')) {
              _whatsappC.text = value.substring(1);
              _whatsappC.selection = TextSelection.fromPosition(
                TextPosition(offset: _whatsappC.text.length),
              );
            }
          },
          decoration: InputDecoration(
            hintText: "8xxxx",
            hintStyle: sRegular.copyWith(color: textMuted),
            prefixText: "+62 ",
            prefixStyle: sRegular.copyWith(color: textMuted),
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

        const SizedBox(height: 16),

        // ===== Shop Address (Optional) =====
        Text("Alamat Toko (Opsional)", style: smBold),
        const SizedBox(height: 8),
        TextField(
          controller: _addressC,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: sRegular.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: "e.g. Jl. Merdeka No. 123, Jakarta",
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
      ]),
    );
  }
}
