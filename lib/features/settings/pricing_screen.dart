import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/ui/color.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _pricePerKiloC = TextEditingController();
  final _blankletC = TextEditingController();
  final _bedsheetC = TextEditingController();
  final _bedcoverC = TextEditingController();
  final _jacketC = TextEditingController();
  final _carpetC = TextEditingController();
  final _otherC = TextEditingController();

  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
          _pricePerKiloC.text = data['pricePerKilo']?.toString() ?? '';
          _blankletC.text = data['blanket']?.toString() ?? '';
          _bedsheetC.text = data['bedsheet']?.toString() ?? '';
          _bedcoverC.text = data['bedcover']?.toString() ?? '';
          _jacketC.text = data['jacket']?.toString() ?? '';
          _carpetC.text = data['smallCarpet']?.toString() ?? '';
          _otherC.text = data['other']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('Error loading pricing: $e');
    }
  }

  Future<void> _savePricingData() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(_userId).set(
        {
          'pricing': {
            'pricePerKilo': double.tryParse(_pricePerKiloC.text) ?? 0,
            'blanket': double.tryParse(_blankletC.text) ?? 0,
            'bedsheet': double.tryParse(_bedsheetC.text) ?? 0,
            'bedcover': double.tryParse(_bedcoverC.text) ?? 0,
            'jacket': double.tryParse(_jacketC.text) ?? 0,
            'smallCarpet': double.tryParse(_carpetC.text) ?? 0,
            'other': double.tryParse(_otherC.text) ?? 0,
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
    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pricing Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Kilogram Section =====
            _buildSectionTitle('Kilogram Pricing'),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'Price per Kilogram (Rp)',
              controller: _pricePerKiloC,
              hintText: 'e.g. 8000',
            ),
            const SizedBox(height: 24),

            // ===== Non-Kilogram Section =====
            _buildSectionTitle('Non-Kilogram Item Prices'),
            const SizedBox(height: 12),
            _buildItemPrice(
              label: 'Blanket',
              controller: _blankletC,
              hintText: 'e.g. 25000',
            ),
            const SizedBox(height: 14),
            _buildItemPrice(
              label: 'Bedsheet',
              controller: _bedsheetC,
              hintText: 'e.g. 15000',
            ),
            const SizedBox(height: 14),
            _buildItemPrice(
              label: 'Bed Cover',
              controller: _bedcoverC,
              hintText: 'e.g. 20000',
            ),
            const SizedBox(height: 14),
            _buildItemPrice(
              label: 'Jacket',
              controller: _jacketC,
              hintText: 'e.g. 18000',
            ),
            const SizedBox(height: 14),
            _buildItemPrice(
              label: 'Small Carpet',
              controller: _carpetC,
              hintText: 'e.g. 30000',
            ),
            const SizedBox(height: 14),
            _buildItemPrice(
              label: 'Other',
              controller: _otherC,
              hintText: 'e.g. 10000',
            ),
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
                    : const Text(
                        'Save Pricing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Section Title Builder =====
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }

  // ===== Input Field Builder =====
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFFD1D5DB),
            ),
            filled: true,
            fillColor: bgInput,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderLight),
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
      ],
    );
  }

  // ===== Item Price Row Builder =====
  Widget _buildItemPrice({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFFD1D5DB),
              ),
              filled: true,
              fillColor: bgInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderFocus, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
