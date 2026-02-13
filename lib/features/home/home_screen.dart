import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'package:laundriin/config/shop_config.dart';
import 'package:laundriin/features/orders/orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _shopName = 'laundriin';

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;

  // Order counts
  int _todayOrdersCount = 0;
  int _waitingCount = 0;
  int _inProcessCount = 0;
  int _completedCount = 0;

  // Recent orders
  List<Map<String, dynamic>> _recentOrders = [];

  // Real-time listeners
  StreamSubscription? _ordersSubscription;

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    return formatter.format(now);
  }

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid ?? '';
    _loadShopName();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    // Cancel listeners saat dispose
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _loadShopName() {
    setState(() {
      _shopName = ShopSettings.shopName;
    });
    print('[LOAD] Shop name from Settings: $_shopName');
  }

  /// ===== SETUP REAL-TIME LISTENERS =====
  void _setupRealtimeListeners() {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Listen to real-time changes di orders collection
      _ordersSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          _updateOrderCounts(snapshot);
          _updateRecentOrders(snapshot);
        }
      }, onError: (e) {
        print('[HOME] ❌ Stream error: $e');
      });

      print('[HOME] ✅ Real-time listeners setup');
    } catch (e) {
      print('[HOME] ❌ Error setup listeners: $e');
    }
  }

  /// ===== UPDATE ORDER COUNTS =====
  void _updateOrderCounts(QuerySnapshot snapshot) {
    int waiting = 0;
    int inProcess = 0;
    int completed = 0;

    // Count by status (exclude cancelled orders)
    for (var doc in snapshot.docs) {
      final status = doc['status'] ?? 'pending';
      // Skip cancelled orders
      if (status == 'cancelled') continue;

      if (status == 'pending') {
        waiting++;
      } else if (status == 'process') {
        inProcess++;
      } else if (status == 'completed') {
        completed++;
      }
    }

    int todayCount =
        waiting + inProcess + completed; // Total = active orders only

    setState(() {
      _todayOrdersCount = todayCount;
      _waitingCount = waiting;
      _inProcessCount = inProcess;
      _completedCount = completed;
    });

    print(
        '[HOME] 🔄 Orders updated - Today: $todayCount, Waiting: $waiting, Process: $inProcess, Completed: $completed');
  }

  /// ===== UPDATE RECENT ORDERS =====
  void _updateRecentOrders(QuerySnapshot snapshot) {
    // Filter out cancelled orders
    final activeDocs = snapshot.docs
        .where((doc) => (doc['status'] ?? 'pending') != 'cancelled')
        .toList();

    activeDocs.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp).toDate();
      final bTime = (b['createdAt'] as Timestamp).toDate();
      return bTime.compareTo(aTime); // Descending
    });

    setState(() {
      _recentOrders = activeDocs
          .take(5)
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });

    print('[HOME] 🔄 Recent orders updated: ${_recentOrders.length}');
  }

  /// ===== MANUAL REFRESH (Pull-to-refresh) =====
  Future<void> _refreshOrders() async {
    print('[HOME] 🔁 Manual refresh triggered');
    // Real-time listener akan auto update, tapi trigger manual juga bisa
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }

  /// ===== NAVIGATE TO ORDERS SCREEN BY STATUS =====
  void _navigateToOrdersScreen(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdersScreen(initialStatus: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshOrders,
          color: blue500,
          backgroundColor: white,
          strokeWidth: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_shopName, style: mBold),
                const SizedBox(height: 6),
                Text(
                  _getFormattedDate(),
                  style: sRegular.copyWith(color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                // ====== Card Income ======
                _buildCardIncome(),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Order Status',
                  style: mBold,
                ),
                const SizedBox(height: 15),
                // ====== Order Status Grid ======
                _buildOrderStatusGrid(),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Recent Orders',
                  style: mBold,
                ),
                const SizedBox(
                  height: 15,
                ),
                _buildRecentOrders()
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ====== Order Status Grid (4 cards) ======
  Widget _buildOrderStatusGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        // Today's Orders - NON-CLICKABLE
        _buildOrderCard(
          icon: Icons.inventory_2_rounded,
          iconColor: const Color(0xFF8B3DFF),
          count: _todayOrdersCount,
          title: "Today's Orders",
          iconBgColor: const Color(0xFFF3E8FF),
          isClickable: false,
        ),
        // Waiting - CLICKABLE
        _buildOrderCard(
          icon: Icons.schedule_rounded,
          iconColor: const Color(0xFFCA8A04),
          count: _waitingCount,
          title: "Waiting",
          iconBgColor: const Color(0xFFFEF9C3),
          isClickable: true,
        ),
        // In Process - CLICKABLE
        _buildOrderCard(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: const Color(0xFF2563EB),
          count: _inProcessCount,
          title: "In Process",
          iconBgColor: const Color(0xFFE0ECFF),
          isClickable: true,
        ),
        // Completed - CLICKABLE
        _buildOrderCard(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF16A34A),
          count: _completedCount,
          title: "Completed",
          iconBgColor: const Color(0xFFDCFCE7),
          isClickable: true,
        ),
      ],
    );
  }

  // ====== Single Order Card ======
  Widget _buildOrderCard({
    required IconData icon,
    required Color iconBgColor,
    required int count,
    required String title,
    required Color iconColor,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    Widget card = Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: sRegular.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );

    // Wrap dengan GestureDetector jika clickable
    if (isClickable) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  // Container Recent Orders
  Widget _buildRecentOrders() {
    // No orders yet
    if (_recentOrders.isEmpty) {
      return Container(
        width: double.infinity,
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/package.svg',
              width: 55,
              height: 55,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders today yet',
              style: mBold.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New orders will appear here',
              style: sRegular.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Display recent orders
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentOrders.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final order = _recentOrders[index];
          final status = order['status'] ?? 'pending';
          final customerName = order['customerName'] ?? 'Unknown';
          final totalPrice = order['totalPrice'] ?? 0;

          // Status badge color
          Color statusColor;
          String statusLabel;
          switch (status) {
            case 'pending':
              statusColor = const Color(0xFFFEF9C3);
              statusLabel = 'Waiting';
              break;
            case 'process':
              statusColor = const Color(0xFFE0ECFF);
              statusLabel = 'In Process';
              break;
            case 'completed':
              statusColor = const Color(0xFFDCFCE7);
              statusLabel = 'Done';
              break;
            default:
              statusColor = Colors.grey[200]!;
              statusLabel = 'Unknown';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Left: Customer & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: smBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: xsRegular.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: Price & Countdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${_formatCurrency(totalPrice)}',
                      style: smBold,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardIncome() {
    // Hardcode data - nanti ganti dengan database
    const int totalIncomeMonth = 5450000;
    const int incomeToday = 250000;
    const int incomeWeek = 1800000;
    const double trendPercentage = 5.2;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            blue500.withOpacity(0.9),
            blue600.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: blue500.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Income',
                      style: sRegular.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Februari 2026',
                      style: xsRegular.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Rp ',
                style: smBold.copyWith(color: Colors.white),
              ),
              Text(
                _formatCurrency(totalIncomeMonth),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
            ),
          ),

          const SizedBox(height: 14),

          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Today
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hari ini',
                      style: xsRegular.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(incomeToday)}',
                      style: smBold.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Trend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend',
                      style: xsRegular.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          trendPercentage > 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: trendPercentage > 0
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFFCA5A5),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trendPercentage.toStringAsFixed(1)}%',
                          style: smBold.copyWith(
                            color: trendPercentage > 0
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Week
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minggu ini',
                      style: xsRegular.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatCurrency(incomeWeek)}',
                      style: smBold.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper untuk format currency
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match m) => '.',
        );
  }
}
