import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _shopName = 'laundriin';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    return formatter.format(now);
  }

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final shopInfo = doc.data()!['shopInfo'] ?? {};
        final shopName = shopInfo['shopName']?.toString().trim();

        setState(() {
          _shopName = (shopName != null && shopName.isNotEmpty)
              ? shopName
              : 'laundriin';
        });

        print('[LOAD] Shop name: $_shopName');
      }
    } catch (e) {
      print('[ERROR] Loading shop name: $e');
      // Keep default 'laundriin' if error occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
      )),
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
      childAspectRatio: 1.0, // ← Ubah angka ini untuk adjust ukuran kotak
      // 1.0 = square (kotak)
      // 0.8 = lebih tinggi (vertikal)
      // 1.2 = lebih lebar (horizontal)
      children: [
        _buildOrderCard(
          icon: Icons.inventory_2_rounded,
          iconColor: Color(0xFF8B3DFF),
          count: 0,
          title: "Today's Orders",
          iconBgColor: Color(0xFFF3E8FF),
        ),
        _buildOrderCard(
          icon: Icons.schedule_rounded,
          iconColor: Color(0xFFCA8A04),
          count: 0,
          title: "Waiting",
          iconBgColor: const Color(0xFFFEF9C3),
        ),
        _buildOrderCard(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: Color(0xFF2563EB),
          count: 0,
          title: "In Process",
          iconBgColor: const Color(0xFFE0ECFF),
        ),
        _buildOrderCard(
          icon: Icons.check_circle_rounded,
          iconColor: Color(0xFF16A34A),
          count: 0,
          title: "Completed",
          iconBgColor: const Color(0xFFDCFCE7),
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
  }) {
    return Container(
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
  }

  // Container Recent Orders
  Widget _buildRecentOrders() {
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
          // Icon
          SvgPicture.asset(
            'assets/svg/package.svg',
            width: 55,
            height: 55,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 16),
          // Text
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
