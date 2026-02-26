import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/utility/app_loading_overlay.dart';
import 'package:laundriin/utility/receipt_screen.dart';
import 'package:laundriin/config/shop_config.dart';
import 'package:laundriin/services/cloudinary_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({
    super.key,
    required this.orderData,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> _orderData;
  List<String> _photos = []; // Cloud URLs
  Map<String, double> _uploadProgress = {}; // Track upload progress per photo
  Map<String, bool> _isUploading = {}; // Track upload state per photo

  late String _currentStatus;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _orderData = widget.orderData;
    _currentStatus = _orderData['status'] ?? 'pending';

    // ===== LOAD PHOTOS FROM FIRESTORE =====
    _loadPhotosFromFirestore();
  }

  /// Load photos dari Firestore saat screen dibuka
  Future<void> _loadPhotosFromFirestore() async {
    try {
      final doc = await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .doc(_orderData['id'])
          .get();

      if (doc.exists && mounted) {
        final photos = List<String>.from(doc['photos'] ?? []);
        setState(() {
          _photos = photos;
        });
        print('[PHOTOS] ✅ Loaded ${photos.length} photos from Firestore');
      }
    } catch (e) {
      print('[PHOTOS] ❌ Error loading photos: $e');
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);
    AppLoading.show(context, message: 'Memperbarui status...');

    try {
      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .doc(_orderData['id'])
          .update({'status': newStatus});

      setState(() {
        _currentStatus = newStatus;
        _orderData['status'] = newStatus;
      });

      if (mounted) {
        AppLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan diperbarui ke $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppLoading.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Batalkan Pesanan', style: mBold),
              const SizedBox(height: 12),
              Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Tidak',
                            style: smMedium.copyWith(color: Colors.black),
                          ))),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Ya',
                            style: smMedium.copyWith(color: white),
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _updateOrderStatus('cancelled');
      if (mounted) Navigator.pop(context);
    }
  }

// delete order
  Future<void> _deleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Delete Order', style: mBold),
              const SizedBox(height: 12),
              Text(
                  'Apakah Anda yakin ingin menghapus pesanan ini? Tindakan ini tidak dapat dibatalkan.'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Tidak',
                            style: smMedium.copyWith(color: Colors.black),
                          ))),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Ya',
                            style: smMedium.copyWith(color: white),
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      if (_isUpdating) return;

      setState(() => _isUpdating = true);
      AppLoading.show(context, message: 'Menghapus pesanan...');

      try {
        await _firestore
            .collection('shops')
            .doc(_userId)
            .collection('orders')
            .doc(_orderData['id'])
            .delete();

        if (mounted) {
          AppLoading.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppLoading.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _openReceipt() {
    final orderId = _orderData['orderId'] ?? 'N/A';
    final customerName = _orderData['customerName'] ?? 'Unknown';
    final customerPhone = _orderData['customerPhone'] ?? '';
    final totalPrice = _orderData['totalPrice'] ?? 0;
    final category = _orderData['category'] ?? '';
    final serviceType = _orderData['serviceType'] ?? '';
    final speed = _orderData['speed'] ?? '';
    final weight = _orderData['weight'] ?? 0;
    final createdAt = _orderData['createdAt'] as Timestamp?;

    List<ReceiptItem> items = [];
    if (_orderData['items'] != null && _orderData['items'] is Map) {
      (_orderData['items'] as Map).forEach((key, value) {
        items.add(
          ReceiptItem(
            name: value['name'] ?? 'Unknown',
            quantity: value['qty'] ?? 1,
            unit: 'item',
            unitPrice: value['price'] ?? 0,
            totalPrice: (value['price'] ?? 0) * (value['qty'] ?? 1),
          ),
        );
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(
          orderId: orderId,
          customerName: customerName,
          customerPhone: customerPhone,
          kasirName: ShopSettings.currentUserName,
          orderDate: createdAt?.toDate() ?? DateTime.now(),
          estimasiSelesai: DeliveryConfig.calculateEstimatedCompletion(
            createdAt?.toDate() ?? DateTime.now(),
            speed.toLowerCase() == 'express',
          ),
          category: category,
          serviceType: serviceType,
          speed: speed,
          weight: weight,
          items: items,
          totalPrice: totalPrice,
          notes: _orderData['notes'],
          pricePerKilo: 0, // Not available in old data
          expressCharge: 0, // Not available in old data
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _orderData['orderId'] ?? 'N/A';
    final customerName = _orderData['customerName'] ?? 'Unknown';
    final customerPhone = _orderData['customerPhone'] ?? '';
    final category = _orderData['category'] ?? '';
    final speed = _orderData['speed'] ?? '';
    final weight = _orderData['weight'] ?? 0;
    final items = _orderData['items'] as Map? ?? {};
    final totalPrice = _orderData['totalPrice'] ?? 0;
    final createdAt = _orderData['createdAt'] as Timestamp?;
    final notes = _orderData['notes'] ?? '';

    // Format tanggal
    String dateStr = 'N/A';
    if (createdAt != null) {
      dateStr = DateFormat('d MMM yyyy • HH:mm').format(createdAt.toDate());
    }

    // Format category & speed
    String categoryLabel = category.isNotEmpty
        ? category[0].toUpperCase() + category.substring(1)
        : '';
    String speedLabel =
        speed.isNotEmpty ? speed[0].toUpperCase() + speed.substring(1) : '';

    // Status badge
    String statusLabel = 'Menunggu';
    Color statusColor = const Color(0xFF9A6A00);
    Color statusBgColor = const Color(0xFFFFF4C2);

    if (_currentStatus == 'process') {
      statusLabel = 'Memproses';
      statusColor = const Color(0xFF2F5FE3);
      statusBgColor = const Color(0xFFE8F1FF);
    } else if (_currentStatus == 'completed') {
      statusLabel = 'Selesai';
      statusColor = const Color(0xFF1F8F5F);
      statusBgColor = const Color(0xFFE8F8F0);
    } else if (_currentStatus == 'cancelled') {
      statusLabel = 'Dibatalkan';
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    }

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _openReceipt,
            icon: SvgPicture.asset(
              'assets/svg/receipt-2.svg',
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
        ],
        title: Text(
          'Detail Pesanan',
          style: mBold,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== CUSTOMER CARD =====
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          child: SvgPicture.asset(
                            'assets/svg/user.svg',
                            width: 22,
                            height: 22,
                            color: blue500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customerName, style: mBold),
                          const SizedBox(height: 5),
                          Text(
                            customerPhone,
                            style: sRegular.copyWith(color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ID Pesanan: $orderId',
                    style: xsRegular.copyWith(color: textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== STATUS =====
            _sectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: sRegular.copyWith(color: textMuted)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: smSemiBold.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== ORDER INFO =====
            _sectionCard(
              child: Column(
                children: [
                  _infoRow(
                    icon: 'assets/svg/basket.svg',
                    title: 'Kategori',
                    value: categoryLabel,
                  ),
                  _infoRow(
                    icon: 'assets/svg/speed.svg',
                    title: 'Kecepatan',
                    value: speedLabel,
                  ),
                  if (weight > 0)
                    _infoRow(
                      icon: 'assets/svg/box.svg',
                      title: 'Berat',
                      value: '$weight kg',
                    ),
                  if (items.isNotEmpty)
                    _infoRow(
                      icon: 'assets/svg/box.svg',
                      title: 'Item',
                      value: '${items.length} buah',
                    ),
                  if (notes.isNotEmpty)
                    _infoRow(
                      icon: 'assets/svg/notes.svg',
                      title: 'Catatan',
                      value: notes,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== PRICE =====
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Harga Total',
                      style: sRegular.copyWith(color: textMuted)),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${_formatNumber(totalPrice)}',
                    style: lBold.copyWith(color: Colors.blue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== CREATED TIME =====
            _sectionCard(
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Dibuat: $dateStr',
                    style: sRegular.copyWith(color: textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Photos (Only show on COMPLETED status) =====
            if (_currentStatus == 'completed') ...[
              _buildPhotos(),
              const SizedBox(height: 16),
            ],

            // ===== ACTION BUTTONS =====
            Column(
              children: [
                if (_currentStatus == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating
                          ? null
                          : () => _updateOrderStatus('process'),
                      child: Text(
                        'Mulai Proses',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating ? null : _cancelOrder,
                      child: Text(
                        'Batalkan Pesanan',
                        style: smSemiBold.copyWith(color: Colors.red),
                      ),
                    ),
                  ),
                ] else if (_currentStatus == 'process') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating
                          ? null
                          : () => _updateOrderStatus('completed'),
                      child: Text(
                        'Selesai',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ] else if (_currentStatus == 'completed') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Open WhatsApp or similar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Integrasi WhatsApp akan segera hadir'),
                          ),
                        );
                      },
                      child: Text(
                        'Pesan di WhatsApp',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ] else if (_currentStatus == 'cancelled') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUpdating ? null : _deleteOrder,
                      child: Text(
                        'Hapus Pesanan',
                        style: smSemiBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== REUSABLE SECTION CARD =====
  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow({
    required String icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            child: SvgPicture.asset(icon, color: iconButtonOutlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: sRegular.copyWith(color: textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: smSemiBold,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===== CLOUDINARY: PICK IMAGE DARI CAMERA =====
  Future<void> _pickAndUploadFromCamera() async {
    try {
      final tempId = 'photo-camera-${DateTime.now().millisecondsSinceEpoch}';

      // Add temporary loading item
      setState(() {
        _isUploading[tempId] = true;
        _uploadProgress[tempId] = 0.0;
        _photos.add(tempId); // Add placeholder
      });

      final secureUrl = await _cloudinaryService.pickAndUploadImage(
        orderId: _orderData['id'] ?? 'unknown',
        source: ImageSource.camera,
        photoType: 'order-photo',
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress[tempId] = progress;
            });
          }
        },
      );

      // Success - replace temp with actual URL
      if (mounted) {
        setState(() {
          final index = _photos.indexOf(tempId);
          if (index != -1) {
            _photos[index] = secureUrl;
          }
          _isUploading.remove(tempId);
          _uploadProgress.remove(tempId);
        });

        // Save to Firestore immediately
        await _savePhotosToFirestore();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto berhasil diupload'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _photos.removeWhere((p) => _isUploading.containsKey(p));
          for (final key in _isUploading.keys.toList()) {
            if (key.startsWith('photo-camera-')) {
              _isUploading.remove(key);
              _uploadProgress.remove(key);
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ===== CLOUDINARY: PICK IMAGE DARI GALLERY =====
  Future<void> _pickAndUploadFromGallery() async {
    try {
      final tempId = 'photo-gallery-${DateTime.now().millisecondsSinceEpoch}';

      // Add temporary loading item
      setState(() {
        _isUploading[tempId] = true;
        _uploadProgress[tempId] = 0.0;
        _photos.add(tempId); // Add placeholder
      });

      final secureUrl = await _cloudinaryService.pickAndUploadImage(
        orderId: _orderData['id'] ?? 'unknown',
        source: ImageSource.gallery,
        photoType: 'order-photo',
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress[tempId] = progress;
            });
          }
        },
      );

      // Success - replace temp with actual URL
      if (mounted) {
        setState(() {
          final index = _photos.indexOf(tempId);
          if (index != -1) {
            _photos[index] = secureUrl;
          }
          _isUploading.remove(tempId);
          _uploadProgress.remove(tempId);
        });

        // Save to Firestore immediately
        await _savePhotosToFirestore();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto berhasil diupload'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _photos.removeWhere((p) => _isUploading.containsKey(p));
          for (final key in _isUploading.keys.toList()) {
            if (key.startsWith('photo-gallery-')) {
              _isUploading.remove(key);
              _uploadProgress.remove(key);
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ===== SAVE PHOTOS TO FIRESTORE =====
  Future<void> _savePhotosToFirestore() async {
    try {
      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .doc(_orderData['id'])
          .update({
        'photos': _photos,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[FIRESTORE] ✅ Photos saved: $_photos');
    } catch (e) {
      print('[FIRESTORE] ❌ Error saving photos: $e');
      // Don't show error snackbar karena user sudah tau foto uploadnya berhasil
    }
  }

  // ===== DELETE PHOTO =====
  Future<void> _deletePhoto(String photoUrl) async {
    try {
      setState(() {
        _photos.remove(photoUrl);
      });

      await _savePhotosToFirestore();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Foto dihapus'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _photos.add(photoUrl); // Revert
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===== SHOW PHOTO SOURCE PICKER =====
  void _showPhotoSourcePicker() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ambil Foto Dari',
                    style: mBold,
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/svg/camera-22.svg',
                      width: 25,
                      height: 25,
                    ),
                    title: Text(
                      'Kamera',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadFromCamera();
                    },
                  ),
                  ListTile(
                    leading: SvgPicture.asset(
                      'assets/svg/image-galery-2.svg',
                      width: 25,
                      height: 25,
                    ),
                    title: const Text('Galeri'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadFromGallery();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  // ===== SHOW IMAGE PREVIEW FULLSCREEN =====
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fullscreen Image
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black87,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            white.withOpacity(0.7)),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal load gambar',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== add photos =====
  Widget _buildPhotos() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Photos (Optional)',
              style: sRegular.copyWith(color: textMuted)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length + 1, // extra 1 buat tombol add
              itemBuilder: (context, index) {
                // ===== BOX ADD PHOTO =====
                if (index == _photos.length) {
                  return GestureDetector(
                    onTap: _showPhotoSourcePicker,
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        color: const Color(0xFFF8F8F8),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 28, color: Colors.grey),
                      ),
                    ),
                  );
                }

                // ===== PHOTO ITEM WITH DELETE & LOADING =====
                final photoUrl = _photos[index];
                final isUploading = _isUploading[photoUrl] ?? false;
                final progress = _uploadProgress[photoUrl] ?? 0.0;

                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      // Photo Container with Loading
                      GestureDetector(
                        onTap: isUploading
                            ? null
                            : () => _showImagePreview(photoUrl),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            image: !isUploading
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: isUploading ? Colors.grey.shade100 : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isUploading
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                blue500),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${(progress * 100).toStringAsFixed(0)}%',
                                        style: xsRegular.copyWith(
                                          fontSize: 10,
                                          color: blue500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),

                      // Delete Button
                      if (!isUploading)
                        Positioned(
                          top: 1,
                          right: 10,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 32, 24, 24),
                                      decoration: BoxDecoration(
                                        color: white,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Hapus Foto', style: mBold),
                                          const SizedBox(height: 12),
                                          Text(
                                              'Apakah anda yakin ingin menghapus foto ini?'),
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                  child: ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFFF3F4F6),
                                                        elevation: 0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                      ),
                                                      child: Text(
                                                        'Tidak',
                                                        style:
                                                            smMedium.copyWith(
                                                                color: Colors
                                                                    .black),
                                                      ))),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                  child: ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context,
                                                              _deletePhoto(
                                                                  photoUrl)),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        elevation: 0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                      ),
                                                      child: Text(
                                                        'Yes',
                                                        style:
                                                            smMedium.copyWith(
                                                                color: white),
                                                      ))),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }
}
