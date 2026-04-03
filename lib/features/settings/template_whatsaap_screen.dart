import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/config/shop_config.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'dart:async';

class TemplateWhatsaapScreen extends StatefulWidget {
  const TemplateWhatsaapScreen({super.key});

  @override
  State<TemplateWhatsaapScreen> createState() => _TemplateWhatsaapScreenState();
}

class _TemplateWhatsaapScreenState extends State<TemplateWhatsaapScreen> {
  // Kategori internal (Firestore)
  final List<String> _categories = [
    'Menunggu',
    'Selesai',
  ];

  // Mapping Label UI
  final Map<String, String> _categoryLabels = {
    'Menunggu': 'Order Masuk',
    'Selesai': 'Order Selesai',
  };

  // Template data dari Firebase
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;
  StreamSubscription? _templateSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _userId => ShopSettings.shopOwnerId;

  @override
  void initState() {
    super.initState();
    _setupTemplateListener();
  }

  @override
  void dispose() {
    _templateSubscription?.cancel();
    super.dispose();
  }

  // _loadTemplates was redundant

  void _setupTemplateListener() {
    _templateSubscription = _firestore
        .collection('shops')
        .doc(_userId)
        .collection('whatsappTemplates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        // Inisialisasi template default jika kosong
        await _initializeDefaultTemplates();
      } else {
        setState(() {
          _templates = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'category': data['category'] ?? 'Proses',
              'message': data['message'] ?? '',
              'isActive': data['isActive'] ?? true,
            };
          }).toList();
          _isLoading = false;
        });
      }
    }, onError: (e) {
      print('[TEMPLATE] Error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _initializeDefaultTemplates() async {
    final List<Map<String, dynamic>> defaultTemplates = [
      {
        'category': 'Menunggu',
        'title': 'Order Masuk',
        'message':
            'Halo {nama}, pesanan laundry Anda dengan ID {orderId} sudah kami terima. Total biaya: Rp {harga}. Estimasi selesai: {estimasi}. Terima kasih!',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'category': 'Selesai',
        'title': 'Order Selesai',
        'message':
            'Halo {nama}, kabar gembira! Pesanan laundry Anda dengan ID {orderId} sudah selesai dan siap diambil. Silakan datang ke outlet kami. Terima kasih!',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var t in defaultTemplates) {
      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('whatsappTemplates')
          .add(t);
    }
  }

  // Variabel yang bisa digunakan
  final List<Map<String, String>> _variables = [
    {'key': '{nama}', 'label': 'Nama'},
    {'key': '{orderId}', 'label': 'No. Pesanan'},
    {'key': '{harga}', 'label': 'Harga'},
    {'key': '{estimasi}', 'label': 'Estimasi'},
    {'key': '{tanggal}', 'label': 'Tanggal'},
    {'key': '{phone}', 'label': 'No. HP'},
    {'key': '{layanan}', 'label': 'Layanan'},
    {'key': '{berat}', 'label': 'Berat'},
    {'key': '{link}', 'label': 'Link Lacak'},
  ];

  List<Map<String, dynamic>> get _fixedTemplates {
    // Pastikan urutan selalu Order Masuk lalu Order Selesai
    final orderMasuk =
        _templates.where((t) => t['category'] == 'Menunggu').toList();
    final orderSelesai =
        _templates.where((t) => t['category'] == 'Selesai').toList();

    return [...orderMasuk, ...orderSelesai];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Column(children: [
          // ===== HEADER =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildHeader(),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            // ===== TEMPLATE LIST =====
            Expanded(
              child: _fixedTemplates.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _fixedTemplates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final template = _fixedTemplates[index];
                        return _buildTemplateCard(template);
                      },
                    ),
            ),
          ],
        ]),
      ),

      // Hapus FAB karena slot sudah tetap
    );
  }

  // ===== HEADER =====
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
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
                Text('Pesan Otomatis', style: mBold),
                const SizedBox(height: 4),
                Text(
                  'Kelola pesan notifikasi otomatis WhatsApp',
                  style: sRegular.copyWith(color: gray500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // _buildTab dihapus karena kategori tidak lagi difilter

  // ===== TEMPLATE CARD =====
  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final bool isActive = template['isActive'] as bool;
    final String category = template['category'] as String;
    final String message = template['message'] as String;

    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.transparent : gray200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===== Card Header =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getCategoryBgColor(category),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      _getCategoryIcon(category),
                      width: 18,
                      color: _getCategoryColor(category),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title & category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _categoryLabels[category] ?? category,
                        style: smBold.copyWith(
                          color: textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dikirim otomatis saat status "${category == 'Menunggu' ? 'Pesanan Masuk' : 'Pesanan Selesai'}"',
                        style: xsRegular.copyWith(color: gray500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== Message Preview =====
          GestureDetector(
            onTap: () => _showPreviewSheet(template),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 12,
                        color: const Color(0xFF25D366).withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Preview Pesan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF25D366).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.length > 120
                        ? '${message.substring(0, 120)}...'
                        : message,
                    style: xsRegular.copyWith(
                      color: const Color(0xFF374151),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ===== Action Buttons =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                _buildActionChip(
                  icon: 'assets/svg/compose.svg',
                  label: 'Edit Pesan',
                  onTap: () => _showEditTemplateSheet(template: template),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 8 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: (iconColor ?? gray500).withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SvgPicture.asset(
                icon,
                width: 14,
                color: iconColor ?? gray500,
              ),
            ),
            const SizedBox(width: 4),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: iconColor ?? gray500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: gray100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: gray300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada template',
            style: smBold.copyWith(color: gray400),
          ),
          const SizedBox(height: 6),
          Text(
            'Buat template pesan untuk\nnotifikasi WhatsApp',
            textAlign: TextAlign.center,
            style: xsRegular.copyWith(color: gray400),
          ),
        ],
      ),
    );
  }

  // ===== PREVIEW BOTTOM SHEET (WhatsApp Style) =====
  void _showPreviewSheet(Map<String, dynamic> template) {
    final String message = template['message'] as String;

    // Replace variables with dummy data for preview
    String previewMessage = message
        .replaceAll('{nama}', 'Andi Pratama')
        .replaceAll('{orderId}', 'ORD-12345')
        .replaceAll('{harga}', '45.000')
        .replaceAll('{estimasi}', '2 hari')
        .replaceAll('{tanggal}', '03 Apr 2024')
        .replaceAll('{phone}', '081234567890')
        .replaceAll('{layanan}', 'Cuci Lipat Reguler')
        .replaceAll('{berat}', '5 kg')
        .replaceAll('{link}', 'laundriin.com/track/ORD-12345');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pratinjau Pesan', style: mBold),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: gray100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 20, color: gray500),
                    ),
                  ),
                ],
              ),
            ),

            // WhatsApp Simulation Area
            Expanded(
              child: Container(
                color: const Color(0xFFEFEAE2), // WhatsApp background color
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Chat header info (optional but nice)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4EAF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pesan dikirim dari Toko Laundry',
                          style: TextStyle(
                              fontSize: 11, color: Colors.blueGrey[800]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp Bubble
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(ctx).size.width * 0.8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.15),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              previewMessage,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '12:45',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditTemplateSheet(template: template);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue500,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Edit Pesan Ini',
                    style: mBold.copyWith(color: white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== EDIT / ADD TEMPLATE BOTTOM SHEET =====
  void _showEditTemplateSheet({Map<String, dynamic>? template}) {
    final bool isEdit = template != null;
    final titleC = TextEditingController(text: isEdit ? template['title'] : '');
    final messageC =
        TextEditingController(text: isEdit ? template['message'] : '');
    String selectedCategory =
        isEdit ? template['category'] : _categories[1]; // default "Konfirmasi"

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        isEdit ? 'Edit Template' : 'Buat Template Baru',
                        style: mBold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Divider(height: 1, color: gray200),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Label (non-editable as it is a slot)
                        Text('Jenis Notifikasi',
                            style: smBold.copyWith(
                                color: textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: gray50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: gray200),
                          ),
                          child: Text(
                            _categoryLabels[selectedCategory] ??
                                selectedCategory,
                            style: smMedium.copyWith(color: textPrimary),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Kategori Selection Removed as slots are fixed
                        const SizedBox(height: 18),

                        // Pesan template
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Isi Pesan',
                                style: smBold.copyWith(
                                    color: textPrimary, fontSize: 13)),
                            Text(
                              '${messageC.text.length} karakter',
                              style: xsRegular.copyWith(
                                  color: gray400, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: messageC,
                          maxLines: 6,
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan template di sini...',
                            hintStyle:
                                sRegular.copyWith(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: gray200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: gray200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: blue500),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Variable chips
                        Text('Tap variabel untuk menyisipkan:',
                            style: xsRegular.copyWith(
                                color: gray400, fontSize: 11)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _variables.map((v) {
                            return GestureDetector(
                              onTap: () {
                                final currentPos =
                                    messageC.selection.baseOffset;
                                final text = messageC.text;
                                final newText = currentPos >= 0
                                    ? text.substring(0, currentPos) +
                                        v['key']! +
                                        text.substring(currentPos)
                                    : text + v['key']!;
                                messageC.text = newText;
                                messageC.selection = TextSelection.fromPosition(
                                  TextPosition(
                                      offset: (currentPos >= 0
                                              ? currentPos
                                              : text.length) +
                                          v['key']!.length),
                                );
                                setModalState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: blue50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: blue200),
                                ),
                                child: Text(
                                  v['key']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: blue600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Save button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: white,
                    border: Border(top: BorderSide(color: gray100)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleC.text.trim().isEmpty ||
                            messageC.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Judul dan isi pesan wajib diisi'),
                              backgroundColor: danger,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

                        _saveTemplate(
                          id: isEdit ? template['id'] : null,
                          title: titleC.text.trim(),
                          category: selectedCategory,
                          message: messageC.text.trim(),
                          isEdit: isEdit,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue500,
                        elevation: 2,
                        shadowColor: blue500.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Simpan Perubahan' : 'Buat Template',
                        style: smBold.copyWith(color: white, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Removed _showDeleteDialog because slots are fixed

  // ===== FIREBASE CRUD =====
  Future<void> _saveTemplate({
    String? id,
    required String title,
    required String category,
    required String message,
    required bool isEdit,
  }) async {
    try {
      final data = {
        'title': title,
        'category': category,
        'message': message,
        'isActive': true,
      };

      if (isEdit && id != null) {
        await _firestore
            .collection('shops')
            .doc(_userId)
            .collection('whatsappTemplates')
            .doc(id)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('shops')
            .doc(_userId)
            .collection('whatsappTemplates')
            .add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Template berhasil diperbarui'
                : 'Template berhasil dibuat'),
            backgroundColor: const Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Removed _deleteTemplate

  // ===== HELPERS =====
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Proses':
        return const Color(0xFF2F5FE3); // orange
      case 'Menunggu':
        return const Color(0xFF9A6A00); // amber
      case 'Selesai':
        return const Color(0xFF1F8F5F); // green
      default:
        return gray500;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category) {
      case 'Proses':
        return const Color(0xFFE8F1FF); // orange bg
      case 'Menunggu':
        return const Color(0xFFFFF4C2); // amber bg
      case 'Selesai':
        return const Color(0xFFE8F8F0); // green bg
      default:
        return gray100;
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Proses':
        return 'assets/svg/reload.svg';
      case 'Menunggu':
        return 'assets/svg/time-left.svg';
      case 'Selesai':
        return 'assets/svg/check-mark-2.svg';
      default:
        return 'assets/svg/communication-2.svg';
    }
  }
}
