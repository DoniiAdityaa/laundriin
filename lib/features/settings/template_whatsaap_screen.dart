import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Kategori filter
  String _selectedCategory = 'Semua';
  final List<String> _categories = [
    'Semua',
    'Menunggu',
    'Proses',
    'Selesai',
  ];

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
    _loadTemplates();
  }

  @override
  void dispose() {
    _templateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final doc = await _firestore.collection('shops').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!['whatsappTemplates'] ?? {};
        setState(() {
          _templates = data.entries.map((entry) {
            final template = entry.value;
            return {
              'id': entry.key,
              'title': template['title'] ?? '',
              'category': template['category'] ?? 'Proses',
              'message': template['message'] ?? '',
              'isActive': template['isActive'] ?? true,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[TEMPLATE] Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupTemplateListener() {
    _templateSubscription = _firestore
        .collection('shops')
        .doc(_userId)
        .collection('whatsappTemplates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
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
  ];

  List<Map<String, dynamic>> get _filteredTemplates {
    if (_selectedCategory == 'Semua') return _templates;
    return _templates.where((t) => t['category'] == _selectedCategory).toList();
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
            const Center(child: CircularProgressIndicator())
          else ...[
            // ===== CATEGORY FILTER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      _buildTab("Semua", 0),
                      const SizedBox(width: 6),
                      _buildTab("Menunggu", 1),
                      const SizedBox(width: 6),
                      _buildTab("Proses", 2),
                      const SizedBox(width: 6),
                      _buildTab("Selesai", 3),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== TEMPLATE LIST =====
            Expanded(
              child: _filteredTemplates.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _filteredTemplates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final template = _filteredTemplates[index];
                        return _buildTemplateCard(template);
                      },
                    ),
            ),
          ],
        ]),
      ),

      // ===== FAB: ADD TEMPLATE =====
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditTemplateSheet(),
        backgroundColor: blue500,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        child: const Icon(Icons.add_rounded, size: 20, color: white),
      ),
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
                Text('Template WhatsApp', style: mBold),
                const SizedBox(height: 4),
                Text(
                  'Kelola pesan template notifikasi',
                  style: sRegular.copyWith(color: gray500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== BUILD TAB =====
  Widget _buildTab(String title, int index) {
    final String categoryValue = _categories[index];
    final bool isActive = _selectedCategory == categoryValue;

    Color activeColor = blue600;
    Color inactiveText = Colors.grey.shade600;

    // Icon & warna per tab (hanya untuk non-Semua)
    String? tabIcon;
    Color iconColor = gray400;
    Color iconBgColor = gray100;

    if (index != 0) {
      tabIcon = _getCategoryIcon(categoryValue);
      iconColor = _getCategoryColor(categoryValue);
      iconBgColor = _getCategoryBgColor(categoryValue);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? blue50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? gray300 : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tabIcon != null) ...[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    tabIcon,
                    width: 13,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: smSemiBold.copyWith(
                color: isActive ? activeColor : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        template['title'] as String,
                        style: smBold.copyWith(
                          color: textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          category,
                          style: xsSemiBold.copyWith(
                            color: _getCategoryColor(category),
                          ),
                        ),
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
                  icon: 'assets/svg/view.svg',
                  label: 'Preview',
                  onTap: () => _showPreviewSheet(template),
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: 'assets/svg/compose.svg',
                  label: 'Edit',
                  onTap: () => _showEditTemplateSheet(template: template),
                ),
                const SizedBox(width: 8),
                // _buildActionChip(
                //   icon: Icons.copy_outlined,
                //   label: 'Salin',
                //   onTap: () {
                //     Clipboard.setData(ClipboardData(text: message));
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       SnackBar(
                //         content: const Text('Template berhasil disalin'),
                //         backgroundColor: const Color(0xFF25D366),
                //         behavior: SnackBarBehavior.floating,
                //         shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(10)),
                //       ),
                //     );
                //   },
                // ),

                _buildActionChip(
                  icon: 'assets/svg/delete.svg',
                  label: 'Hapus',
                  iconColor: const Color(0xFFEF4444),
                  onTap: () => _showDeleteDialog(template),
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
        .replaceAll('{nama}', 'Budi Santoso')
        .replaceAll('{orderId}', 'ORD-240101')
        .replaceAll('{harga}', '85.000')
        .replaceAll('{estimasi}', '2 hari')
        .replaceAll('{tanggal}', '25 Feb 2026')
        .replaceAll('{phone}', '0812-3456-7890')
        .replaceAll('{layanan}', 'Cuci + Setrika')
        .replaceAll('{berat}', '3.5 kg');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: blue50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/view.svg',
                        width: 16,
                        color: blue500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Preview Pesan', style: mBold),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.close_rounded, size: 18, color: gray500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Divider(height: 1, color: gray200),
            const SizedBox(height: 16),

            // WhatsApp Chat Bubble
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: blue50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.store_rounded,
                                color: white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Toko Laundry Anda',
                                style: smBold.copyWith(
                                    fontSize: 13, color: textPrimary),
                              ),
                              Text(
                                'Online',
                                style: xsRegular.copyWith(
                                  color: const Color(0xFF25D366),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chat bubble (WhatsApp green style)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(ctx).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF8C6),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              previewMessage,
                              style: sRegular.copyWith(
                                color: const Color(0xFF1B1B1B),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '12:00',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.done_all_rounded,
                                    size: 14, color: const Color(0xFF53BDEB)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Info keterangan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: blue50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: blue100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: blue500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Variabel seperti {nama}, {orderId}, dll akan otomatis diganti dengan data pelanggan saat dikirim.',
                              style: xsRegular.copyWith(
                                color: blue600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom action
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
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
                    'Edit Template',
                    style: smBold.copyWith(color: white, fontSize: 14),
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
                        // Judul Template
                        Text('Judul Template',
                            style: smBold.copyWith(
                                color: textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleC,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Konfirmasi Pesanan',
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Kategori
                        Text('Kategori',
                            style: smBold.copyWith(
                                color: textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _categories.where((c) => c != 'Semua').map((cat) {
                            final isSelected = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() => selectedCategory = cat);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _getCategoryColor(cat).withOpacity(0.12)
                                      : gray50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? _getCategoryColor(cat)
                                        : gray200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _getCategoryColor(cat)
                                                .withOpacity(0.15)
                                            : gray100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          _getCategoryIcon(cat),
                                          width: 12,
                                          color: isSelected
                                              ? _getCategoryColor(cat)
                                              : gray400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? _getCategoryColor(cat)
                                            : gray500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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

  // ===== DELETE DIALOG =====
  void _showDeleteDialog(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text('Hapus Template?',
                  style: smBold.copyWith(fontSize: 17, color: textPrimary)),
              const SizedBox(height: 8),
              Text(
                '"${template['title']}" akan dihapus permanen.',
                textAlign: TextAlign.center,
                style: sRegular.copyWith(color: gray500),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gray100,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Batal',
                          style: smBold.copyWith(
                              color: textPrimary, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteTemplate(template['id']);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Hapus',
                          style: smBold.copyWith(color: white, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Future<void> _deleteTemplate(String id) async {
    try {
      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('whatsappTemplates')
          .doc(id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Template berhasil dihapus'),
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
            content: Text('Gagal menghapus template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
