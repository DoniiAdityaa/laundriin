import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';
import 'widgets/income_trend_chart.dart';
import 'widgets/service_distribution_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedPeriod = 'week'; // week or month

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Income summary state
  int _currentPeriodIncome = 0;
  int _previousPeriodIncome = 0;
  int _currentPeriodOrders = 0;
  StreamSubscription? _incomeSubscription;

  @override
  void initState() {
    super.initState();
    _setupIncomeListener();
  }

  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Listener otomatis update karena period berubah
  }

  @override
  void dispose() {
    _incomeSubscription?.cancel();
    super.dispose();
  }

  void _setupIncomeListener() {
    try {
      final now = DateTime.now();
      late final DateTime currentStart, currentEnd, previousStart, previousEnd;

      if (selectedPeriod == 'week') {
        // Current week (Monday to today)
        currentStart = now.subtract(Duration(days: now.weekday - 1));
        currentEnd = now;

        // Previous week
        previousStart = currentStart.subtract(const Duration(days: 7));
        previousEnd = previousStart.add(const Duration(days: 6));
      } else {
        // Current month
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = now;

        // Previous month
        final prevMonth = currentStart.subtract(const Duration(days: 1));
        previousStart = DateTime(prevMonth.year, prevMonth.month, 1);
        previousEnd = DateTime(prevMonth.year, prevMonth.month + 1, 1)
            .subtract(const Duration(days: 1));
      }

      final currentStartOfDay =
          DateTime(currentStart.year, currentStart.month, currentStart.day);
      final previousStartOfDay =
          DateTime(previousStart.year, previousStart.month, previousStart.day);

      _incomeSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          _calculateIncome(snapshot, currentStartOfDay, previousStartOfDay);
        }
      }, onError: (e) {
        print('[INCOME] Error: $e');
      });

      print('[INCOME] ✅ Listener setup for ${selectedPeriod}');
    } catch (e) {
      print('[INCOME] ❌ Error setup listener: $e');
    }
  }

  void _calculateIncome(
      QuerySnapshot snapshot, DateTime currentStart, DateTime previousStart) {
    int currentIncome = 0;
    int previousIncome = 0;
    int currentOrders = 0;

    for (var doc in snapshot.docs) {
      final createdAt = doc['createdAt'] as Timestamp?;
      final totalPrice = doc['totalPrice'] as int? ?? 0;

      if (createdAt != null) {
        final orderDate = DateTime(
          createdAt.toDate().year,
          createdAt.toDate().month,
          createdAt.toDate().day,
        );

        if (orderDate.isAfter(currentStart) ||
            orderDate.isAtSameMomentAs(currentStart)) {
          currentIncome += totalPrice;
          currentOrders++;
        } else if (orderDate.isAfter(previousStart) ||
            orderDate.isAtSameMomentAs(previousStart)) {
          previousIncome += totalPrice;
        }
      }
    }

    setState(() {
      _currentPeriodIncome = currentIncome;
      _previousPeriodIncome = previousIncome;
      _currentPeriodOrders = currentOrders;
    });

    print(
        '[INCOME] Current: Rp $_currentPeriodIncome | Previous: Rp $_previousPeriodIncome | Orders: $_currentPeriodOrders');
  }

  double _calculateGrowthPercentage() {
    if (_previousPeriodIncome == 0) return 0;
    return ((_currentPeriodIncome - _previousPeriodIncome) /
            _previousPeriodIncome) *
        100;
  }

  int _getAverageOrderPrice() {
    if (_currentPeriodOrders == 0) return 0;
    return (_currentPeriodIncome / _currentPeriodOrders).toInt();
  }

  String _formatCurrency(int value) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Reports", style: mBold),
                    const SizedBox(height: 16),
                    // ===== PERIOD FILTER =====
                    _buildPeriodFilter(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===== CONTENT =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // 1. Income Summary Card
                    _buildIncomeSummary(),
                    const SizedBox(height: 20),

                    // 2. Income Trend Chart
                    _buildIncomeTrend(),
                    const SizedBox(height: 20),

                    // 3. Service Distribution Chart
                    _buildServiceDistribution(),
                    const SizedBox(height: 20),

                    // 4. Revenue by Service Type
                    _buildRevenueByServiceType(),
                    const SizedBox(height: 20),

                    // 5. Top Customers
                    _buildTopCustomers(),
                    const SizedBox(height: 20),

                    // 7. Pending Orders Alert
                    _buildPendingOrdersAlert(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 1. PERIOD FILTER =====
  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gray200,
        ),
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
          _buildPeriodButton('Minggu', 'week'),
          _buildPeriodButton('Bulan', 'month'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isActive = selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedPeriod = value);
          // Refresh listener saat period berubah
          _incomeSubscription?.cancel();
          _setupIncomeListener();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
              color: isActive ? blue50 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? gray300 : Colors.transparent,
              )),
          alignment: Alignment.center,
          child: Text(
            label,
            style: smSemiBold.copyWith(
              color: isActive ? blue600 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 2. INCOME SUMMARY CARD =====
  Widget _buildIncomeSummary() {
    final growthPercent = _calculateGrowthPercentage();
    final isPositiveGrowth = growthPercent >= 0;
    final avgOrderPrice = _getAverageOrderPrice();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== TOP ROW: Label + Trend Badge =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pemasukan',
                    style: sRegular.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    _getPeriodLabel(),
                    style: sRegular.copyWith(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              // Trend badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositiveGrowth
                      ? const Color(0xFF1F8F5F).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositiveGrowth
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositiveGrowth
                          ? const Color(0xFF1F8F5F)
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${growthPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPositiveGrowth
                            ? const Color(0xFF1F8F5F)
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== MAIN AMOUNT =====
          Text(
            _formatCurrency(_currentPeriodIncome),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F5FE3),
            ),
          ),
          const SizedBox(height: 16),

          // ===== DIVIDER =====
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),

          // ===== BOTTOM ROW: Metrics =====
          Row(
            children: [
              // Orders count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesanan',
                      style: xsRegular.copyWith(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_currentPeriodOrders pesanan',
                      style: smBold.copyWith(color: textPrimary),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[200],
              ),
              // Average order price
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rata-rata',
                        style: xsRegular.copyWith(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(avgOrderPrice),
                        style: smBold.copyWith(color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== 3. INCOME TREND CHART =====
  Widget _buildIncomeTrend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Income Trend',
              style: mBold.copyWith(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1F8F5F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '+12.5% this week',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F8F5F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: IncomeTrendChart(period: selectedPeriod),
        ),
      ],
    );
  }

  // ===== 4. SERVICE DISTRIBUTION CHART =====
  Widget _buildServiceDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Layanan',
          style: mBold.copyWith(),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: ServiceDistributionChart(period: selectedPeriod),
        ),
      ],
    );
  }

  // ===== 4. REVENUE BY SERVICE TYPE =====
  Widget _buildRevenueByServiceType() {
    // Dummy data - replace dengan Firebase nanti
    final serviceTypes = [
      {'name': 'Kiloan', 'amount': 1700000, 'color': const Color(0xFF4F7DF3)},
      {'name': 'Satuan', 'amount': 800000, 'color': const Color(0xFF7AA2FF)},
      {'name': 'Express', 'amount': 350000, 'color': const Color(0xFFA5BFFF)},
    ];

    final totalRevenue =
        serviceTypes.fold<int>(0, (sum, item) => sum + (item['amount'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pendapatan per Layanan',
          style: mBold,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: serviceTypes.map((service) {
              final amount = service['amount'] as int;
              final percentage = (amount / totalRevenue * 100);
              final color = service['color'] as Color;
              final name = service['name'] as String;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: smBold.copyWith(color: textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: smBold.copyWith(
                            color: color,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatCurrency(amount),
                      style: xsRegular.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===== 5. TOP CUSTOMERS =====
  Widget _buildTopCustomers() {
    // Dummy data - replace dengan Firebase nanti
    final topCustomers = [
      {
        'name': 'Rudi Hartono',
        'orders': 5,
        'amount': 950000,
        'phone': '081234567890',
      },
      {
        'name': 'Siti Nurhaliza',
        'orders': 4,
        'amount': 760000,
        'phone': '081987654321',
      },
      {
        'name': 'Budi Santoso',
        'orders': 3,
        'amount': 570000,
        'phone': '082123456789',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pelanggan Terbaik',
          style: mBold,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: List.generate(topCustomers.length, (index) {
              final customer = topCustomers[index];
              final rank = index + 1;
              final orders = customer['orders'] as int;
              final amount = customer['amount'] as int;
              final name = customer['name'] as String;

              // Color for rank
              Color rankColor;
              String rankEmoji;
              if (rank == 1) {
                rankColor = const Color(0xFFFFB800);
                rankEmoji = '🥇';
              } else if (rank == 2) {
                rankColor = const Color(0xFFC0C0C0);
                rankEmoji = '🥈';
              } else {
                rankColor = const Color(0xFFCD7F32);
                rankEmoji = '🥉';
              }

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rankColor),
                      ),
                      child: Center(
                        child: Text(
                          rankEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Customer info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: smBold.copyWith(color: textPrimary),
                          ),
                          Text(
                            '$orders pesanan',
                            style: xsRegular.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(amount),
                          style: smBold.copyWith(color: blue600),
                        ),
                        Text(
                          'Total',
                          style: xsRegular.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===== 6. STATUS ORDERS SUMMARY =====
  Widget _buildStatusOrdersSummary() {
    // Dummy data - replace dengan Firebase nanti
    final statusData = [
      {
        'label': 'Selesai',
        'count': 30,
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF1F8F5F),
        'bgColor': const Color(0xFF1F8F5F).withOpacity(0.1),
      },
      {
        'label': 'Proses',
        'count': 12,
        'icon': Icons.autorenew_rounded,
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFF59E0B).withOpacity(0.1),
      },
      {
        'label': 'Pending',
        'count': 5,
        'icon': Icons.schedule_rounded,
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFF3B82F6).withOpacity(0.1),
      },
      {
        'label': 'Batal',
        'count': 2,
        'icon': Icons.cancel_rounded,
        'color': Colors.red,
        'bgColor': Colors.red.withOpacity(0.1),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Pesanan',
          style: mBold,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: statusData.map((status) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: status['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      status['icon'] as IconData,
                      color: status['color'] as Color,
                      size: 24,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        (status['count'] as int).toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        status['label'] as String,
                        style: xsRegular.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===== 7. PENDING ORDERS ALERT =====
  Widget _buildPendingOrdersAlert() {
    // Dummy data - replace dengan Firebase nanti
    final pendingOrders = [
      {
        'orderId': 'ORD-2026-02-18-001',
        'customerName': 'Rudi Hartono',
        'daysOverdue': 2,
        'totalPrice': 150000,
      },
      {
        'orderId': 'ORD-2026-02-17-002',
        'customerName': 'Siti Nurhaliza',
        'daysOverdue': 1,
        'totalPrice': 200000,
      },
      {
        'orderId': 'ORD-2026-02-16-003',
        'customerName': 'Budi Santoso',
        'daysOverdue': 3,
        'totalPrice': 175000,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pesanan Tertunda',
              style: mBold,
            ),
            if (pendingOrders.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pendingOrders.length} pesanan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (pendingOrders.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF1F8F5F),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada pesanan tertunda',
                    style: smBold.copyWith(color: const Color(0xFF1F8F5F)),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingOrders.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final order = pendingOrders[index];
                final daysOverdue = order['daysOverdue'] as int;
                final isUrgent = daysOverdue > 2;

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Alert badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? Colors.red.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: isUrgent ? Colors.red : Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Order details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['customerName'] as String,
                              style: smBold.copyWith(color: textPrimary),
                            ),
                            Text(
                              '${order['orderId']} • ${daysOverdue} hari terlewat',
                              style:
                                  xsRegular.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      // Action button
                      Column(
                        children: [
                          Text(
                            _formatCurrency(order['totalPrice'] as int),
                            style: smBold.copyWith(
                              color: isUrgent ? Colors.red : Colors.orange,
                            ),
                          ),
                          Text(
                            'Hubungi',
                            style: xsRegular.copyWith(
                              color: isUrgent ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ===== HELPER FUNCTION =====
  String _getPeriodLabel() {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return 'Minggu ini (${startOfWeek.day} - ${now.day} ${_getMonthName(now.month)})';
      case 'month':
      default:
        return '${_getMonthName(now.month)} ${now.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
