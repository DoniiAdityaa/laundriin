import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/features/add_order/order_detail_screen.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/shared_widget/order_card_screen.dart';
import 'package:laundriin/ui/typography.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterOrders);
    _loadOrders();
  }

  @override
  void dispose() {
    searchController.dispose();
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

      setState(() {
        _allOrders = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _isLoading = false;
        print('[ORDERS] Loaded ${_allOrders.length} orders');
      });

      _filterOrders();
    } catch (e) {
      print('[ERROR] Load orders: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterOrders() {
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
      statusFilter = 'cancelled'; // Cancel ✅
    } else {
      statusFilter = 'Cancel';
    }

    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final orderStatus = order['status'] ?? 'pending';
        final customerName =
            order['customerName']?.toString().toLowerCase() ?? '';
        final orderId = order['orderId']?.toString().toLowerCase() ?? '';

        // Filter by status
        bool statusMatch = orderStatus == statusFilter;

        // Filter by search
        bool searchMatch = searchText.isEmpty ||
            customerName.contains(searchText) ||
            orderId.contains(searchText);

        return statusMatch && searchMatch;
      }).toList();
    });

    print('[FILTER] Status: $statusFilter, Results: ${_filteredOrders.length}');
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
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
                  const Text("Orders", style: mBold),
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
                    child: Row(
                      children: [
                        _buildTab("Waiting", 0),
                        _buildTab("Process", 1),
                        _buildTab("Done", 2),
                        _buildTab("Cancel", 3),
                      ],
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

    Color bgColor;
    Color textColor;

    if (index == 0) {
      bgColor = const Color(0xFFFFF4C2); // soft yellow
      textColor = const Color(0xFF9A6A00);
    } else if (index == 1) {
      bgColor = const Color(0xFFE8F1FF); // soft blue
      textColor = const Color(0xFF2F5FE3);
    } else if (index == 2) {
      bgColor = const Color(0xFFE8F8F0); // soft green
      textColor = const Color(0xFF1F8F5F);
    } else {
      bgColor = const Color(0xFFFFEAEA); // Cancel (soft red)
      textColor = const Color(0xFFC62828);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
          _filterOrders();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? bgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.grey[300]! : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: smSemiBold.copyWith(
              color: isActive ? textColor : Colors.grey,
            ),
          ),
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
            'No orders',
            style: mBold.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'No orders in this status yet',
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
