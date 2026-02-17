import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/features/add_order/order_detail_screen.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/shared_widget/order_card_screen.dart';
import 'package:laundriin/ui/typography.dart';

class OrdersScreen extends StatefulWidget {
  final String? initialStatus;

  const OrdersScreen({super.key, this.initialStatus});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final searchController = TextEditingController();
  int selectedTab = 0;

  // Firestore & Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Orders data
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;

  // Order counts by status
  int _pendingCount = 0;
  int _processCount = 0;

  // Real-time listener
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterOrders);

    // Set selectedTab based on initialStatus
    if (widget.initialStatus != null) {
      if (widget.initialStatus == 'pending') {
        selectedTab = 0;
      } else if (widget.initialStatus == 'process') {
        selectedTab = 1;
      } else if (widget.initialStatus == 'completed') {
        selectedTab = 2;
      } else if (widget.initialStatus == 'cancelled') {
        selectedTab = 3;
      }
    }

    _setupRealtimeListener();
    _loadOrders();
  }

  @override
  void dispose() {
    searchController.removeListener(_filterOrders);
    searchController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      print('[ORDERS] Loading orders from Firestore...');
      final snapshot = await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _allOrders = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          _updateOrderCounts();
          _isLoading = false;
          print('[ORDERS] Loaded ${_allOrders.length} orders');
        });

        _filterOrders();
      }
    } catch (e) {
      print('[ERROR] Load orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ===== SETUP REAL-TIME LISTENER =====
  void _setupRealtimeListener() {
    try {
      _ordersSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _allOrders = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
            _updateOrderCounts();
          });
          _filterOrders();
          print('[ORDERS] ✅ Real-time update: ${_allOrders.length} orders');
        }
      }, onError: (e) {
        print('[ORDERS] ❌ Stream error: $e');
      });

      print('[ORDERS] ✅ Real-time listener setup');
    } catch (e) {
      print('[ORDERS] ❌ Error setup listener: $e');
    }
  }

  void _updateOrderCounts() {
    _pendingCount = _allOrders.where((o) => o['status'] == 'pending').length;
    _processCount = _allOrders.where((o) => o['status'] == 'process').length;
  }

  /// Calculate filtered orders without setState
  List<Map<String, dynamic>> _calculateFilteredOrders() {
    final searchText = searchController.text.toLowerCase();

    // Map tab index ke status
    String statusFilter;
    if (selectedTab == 0) {
      statusFilter = 'pending'; // Waiting
    } else if (selectedTab == 1) {
      statusFilter = 'process'; // Process
    } else if (selectedTab == 2) {
      statusFilter = 'completed'; // Done
    } else if (selectedTab == 3) {
      statusFilter = 'cancelled'; // Cancel
    } else {
      statusFilter = 'Cancel';
    }

    // Lazy load: hanya filter orders untuk tab yang active
    final ordersForTab = _allOrders
        .where((order) => (order['status'] ?? 'pending') == statusFilter)
        .toList();

    // Kemudian apply search filter
    return ordersForTab.where((order) {
      final customerName =
          order['customerName']?.toString().toLowerCase() ?? '';
      final orderId = order['orderId']?.toString().toLowerCase() ?? '';

      bool searchMatch = searchText.isEmpty ||
          customerName.contains(searchText) ||
          orderId.contains(searchText);

      return searchMatch;
    }).toList();
  }

  void _filterOrders() {
    if (mounted) {
      setState(() {
        _filteredOrders = _calculateFilteredOrders();
      });

      print('[FILTER] Tab: $selectedTab, Results: ${_filteredOrders.length}');
    }
  }

  Future<void> _onRefresh() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER (FIXED) =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text("Pesanan", style: mBold),
                  const SizedBox(height: 14),
                  // Searching
                  _buildSearchBar(
                    hintText: 'Cari Pelanggan..',
                    controller: searchController,
                  ),
                  const SizedBox(height: 16),
                  // Tabs
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                          _buildTab("Menunggu", 0),
                          const SizedBox(width: 6),
                          _buildTab("Proses", 1),
                          const SizedBox(width: 6),
                          _buildTab("Selesai", 2),
                          const SizedBox(width: 6),
                          _buildTab("Batal", 3),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ===== ORDERS LIST (SCROLLABLE WITH REFRESH) =====
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildRecentOrders(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required String hintText,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.grey),
          hintText: hintText,
          hintStyle: smRegular,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isActive = selectedTab == index;

    // ===== STYLE =====
    Color activeColor = blue600;
    Color inactiveText = Colors.grey.shade600;

    int count = 0;
    if (index == 0) count = _pendingCount;
    if (index == 1) count = _processCount;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            selectedTab = index;
          });
          _filterOrders();
        }
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
            Text(
              title,
              style: smSemiBold.copyWith(
                color: isActive ? activeColor : inactiveText,
              ),
            ),

            // ===== BADGE INLINE =====
            if (count > 0 && (index == 0 || index == 1)) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: blue600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/svg/package.svg',
            width: 55,
            height: 55,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada pesanan',
            style: mBold.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada pesanan dengan status ini',
            style: sRegular.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Container Recent Orders
  Widget _buildRecentOrders() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredOrders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildEmptyState(),
        ],
      );
    }

    return ListView.builder(
        key: ValueKey('orders_tab_$selectedTab'), // Unique key per tab
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          return OrderCard(
            order: _filteredOrders[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    orderData: _filteredOrders[index],
                  ),
                ),
              );
            },
          );
        });
  }
}
