import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/config/shop_config.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageC = TextEditingController();
  String _selectedCategory = 'Umum';
  int _rating = 0;
  bool _isSending = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Umum', 'icon': Icons.chat_bubble_outline},
    {'label': 'Bug', 'icon': Icons.bug_report_outlined},
    {'label': 'Fitur', 'icon': Icons.lightbulb_outline},
    {'label': 'Lainnya', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _messageC.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_messageC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan feedback tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berikan rating terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final feedbackData = {
        'userId': user?.uid ?? '',
        'userEmail': user?.email ?? '',
        'userName': ShopSettings.currentUserDisplayName,
        'shopName': ShopSettings.shopName,
        'category': _selectedCategory,
        'rating': _rating,
        'message': _messageC.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'unread', // unread, read, resolved
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      if (mounted) {
        setState(() => _isSending = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Terima Kasih!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Feedback Anda telah berhasil dikirim. Kami akan meninjau dan merespons secepatnya.",
                textAlign: TextAlign.center,
                style: sRegular.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue500,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to settings
                  },
                  child: Text(
                    "Kembali",
                    style: sSemiBold.copyWith(color: white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildHeader(
                  title: 'Bantuan & Dukungan',
                  subtitle: 'Hubungi kami jika ada masalah'),
            ),

            const SizedBox(height: 20),

            // ===== Content =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Rating =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Bagaimana pengalaman Anda?',
                            style: smSemiBold.copyWith(color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Berikan rating untuk aplikasi ini',
                            style: xsRegular.copyWith(color: gray500),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starIndex = index + 1;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _rating = starIndex);
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    starIndex <= _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 40,
                                    color: starIndex <= _rating
                                        ? const Color(0xFFFBCA24)
                                        : gray300,
                                  ),
                                ),
                              );
                            }),
                          ),
                          if (_rating > 0) ...[
                            const SizedBox(height: 10),
                            Text(
                              _getRatingText(_rating),
                              style: xsSemiBold.copyWith(
                                color: _rating >= 4
                                    ? const Color(0xFF16A34A)
                                    : _rating >= 3
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Kategori =====
                    Text('Kategori', style: smSemiBold),
                    const SizedBox(height: 10),
                    Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat['label'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = cat['label']);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? blue500 : white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? blue500 : borderLight,
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: blue500.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    cat['icon'] as IconData,
                                    size: 20,
                                    color: isSelected ? white : gray500,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat['label'] as String,
                                    style: xsSemiBold.copyWith(
                                      color: isSelected ? white : gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ===== Pesan Feedback =====
                    Text('Pesan', style: smSemiBold),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messageC,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: sRegular.copyWith(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Ceritakan pengalaman atau masalah Anda...',
                          hintStyle: sRegular.copyWith(color: textMuted),
                          filled: true,
                          fillColor: white,
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: borderLight, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: blue500, width: 1.2),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ===== Tombol Kirim =====
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue500,
                          disabledBackgroundColor: blue300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded,
                                      size: 18, color: white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kirim Feedback',
                                    style: sSemiBold.copyWith(color: white),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== Info Kontak =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: blue50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: blue100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 20, color: blue500),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Feedback akan dikirim ke tim pengembang dan diproses secepatnya.',
                              style: xsRegular.copyWith(color: blue600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Buruk 😞';
      case 2:
        return 'Kurang Baik 😕';
      case 3:
        return 'Cukup Baik 😊';
      case 4:
        return 'Baik 😄';
      case 5:
        return 'Sangat Baik! 🤩';
      default:
        return '';
    }
  }
}
