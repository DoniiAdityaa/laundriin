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

  // Expense state
  int _currentPeriodExpense = 0;
  List<Map<String, dynamic>> _expenseItems = [];
  StreamSubscription? _expenseSubscription;

  @override
  void initState() {
    super.initState();
    _setupIncomeListener();
    _setupExpenseListener();
  }

  @override
  void didUpdateWidget(ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Listener otomatis update karena period berubah
  }

  @override
  void dispose() {
    _incomeSubscription?.cancel();
    _expenseSubscription?.cancel();
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
                    // 1. Financial Summary (Combined Card)
                    _buildFinancialSummary(),
                    const SizedBox(height: 20),

                    // 2. Expense List + Add Button
                    _buildExpenseSection(),
                    const SizedBox(height: 20),

                    // 3. Income Trend Chart
                    _buildIncomeTrend(),
                    const SizedBox(height: 20),

                    // 4. Service Distribution Chart
                    _buildServiceDistribution(),
                    const SizedBox(height: 20),

                    // 6. Top Customers
                    _buildTopCustomers(),
                    const SizedBox(height: 20),

                    // 7. Pending Orders Alert
                    _buildPendingOrdersAlert(),
                    const SizedBox(height: 20),

                    // 8. Download PDF (Single Button)
                    _buildDownloadPdfButton(),
                    const SizedBox(height: 25),
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
          // Refresh listeners saat period berubah
          _incomeSubscription?.cancel();
          _setupIncomeListener();
          _expenseSubscription?.cancel();
          _setupExpenseListener();
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

  // ===== EXPENSE LISTENER =====
  void _setupExpenseListener() {
    try {
      final now = DateTime.now();
      late final DateTime currentStart;

      if (selectedPeriod == 'week') {
        currentStart = now.subtract(Duration(days: now.weekday - 1));
      } else {
        currentStart = DateTime(now.year, now.month, 1);
      }

      final currentStartOfDay =
          DateTime(currentStart.year, currentStart.month, currentStart.day);

      _expenseSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('expenses')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          int totalExpense = 0;
          List<Map<String, dynamic>> items = [];

          for (var doc in snapshot.docs) {
            final createdAt = doc['createdAt'] as Timestamp?;
            final amount = doc['amount'] as int? ?? 0;

            if (createdAt != null) {
              final expenseDate = DateTime(
                createdAt.toDate().year,
                createdAt.toDate().month,
                createdAt.toDate().day,
              );

              if (expenseDate.isAfter(currentStartOfDay) ||
                  expenseDate.isAtSameMomentAs(currentStartOfDay)) {
                totalExpense += amount;
                items.add({
                  'id': doc.id,
                  'name': doc['name'] ?? '',
                  'category': doc['category'] ?? '',
                  'amount': amount,
                  'createdAt': createdAt.toDate(),
                  'note': doc['note'] ?? '',
                });
              }
            }
          }

          // Sort terbaru dulu
          items.sort((a, b) => (b['createdAt'] as DateTime)
              .compareTo(a['createdAt'] as DateTime));

          setState(() {
            _currentPeriodExpense = totalExpense;
            _expenseItems = items;
          });
        }
      }, onError: (e) {
        print('[EXPENSE] Error: $e');
      });

      print('[EXPENSE] ✅ Listener setup for $selectedPeriod');
    } catch (e) {
      print('[EXPENSE] ❌ Error setup listener: $e');
    }
  }

  // ===== ADD EXPENSE TO FIRESTORE =====
  Future<void> _addExpense({
    required String name,
    required String category,
    required int amount,
    String note = '',
  }) async {
    try {
      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('expenses')
          .add({
        'name': name,
        'category': category,
        'amount': amount,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil ditambahkan'),
            backgroundColor: Color(0xFF1F8F5F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan pengeluaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== DELETE EXPENSE =====
  Future<void> _deleteExpense(String expenseId) async {
    try {
      await _firestore
          .collection('shops')
          .doc(_userId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil dihapus'),
            backgroundColor: Color(0xFF1F8F5F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===== COMBINED FINANCIAL SUMMARY CARD =====
  Widget _buildFinancialSummary() {
    final netProfit = _currentPeriodIncome - _currentPeriodExpense;
    final isProfit = netProfit >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          // ===== SISA BERSIH (HERO) =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isProfit
                    ? [blue500.withOpacity(0.92), blue600.withOpacity(0.92)]
                    : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isProfit ? 'Sisa Bersih' : 'Rugi Bersih',
                      style: sRegular.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    Text(
                      _getPeriodLabel(),
                      style: xsRegular.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(netProfit.abs()),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // ===== PEMASUKAN & PENGELUARAN =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                // Pemasukan
                Expanded(
                  child: _summaryTile(
                    label: 'Pemasukan',
                    value: _formatCurrency(_currentPeriodIncome),
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF2F5FE3),
                  ),
                ),
                const SizedBox(width: 12),
                // Pengeluaran
                Expanded(
                  child: _summaryTile(
                    label: 'Pengeluaran',
                    value: _formatCurrency(_currentPeriodExpense),
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),

          // ===== PESANAN & RATA-RATA =====
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  '$_currentPeriodOrders pesanan',
                  style: smBold.copyWith(color: textPrimary, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.grey[300],
                ),
                const Spacer(),
                Icon(Icons.bar_chart_rounded,
                    size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'Avg ${_formatCurrency(_getAverageOrderPrice())}',
                  style: smBold.copyWith(color: textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: xsRegular.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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

  // ===== EXPENSE SECTION (List + Add Button) =====
  Widget _buildExpenseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pengeluaran', style: mBold),
            if (selectedPeriod == 'week')
              GestureDetector(
                onTap: () => _showAddExpenseDialog(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F5FE3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style:
                            smBold.copyWith(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_expenseItems.isEmpty)
          Container(
            width: double.infinity,
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
            child: Container(
              constraints: const BoxConstraints(minHeight: 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: Colors.grey[500], size: 35),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada pengeluaran',
                      style: xsRegular.copyWith(color: Colors.grey[400]),
                    ),
                  ],
                ),
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
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenseItems.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final item = _expenseItems[index];
                final date = item['createdAt'] as DateTime;
                final formattedDate =
                    DateFormat('dd MMM yyyy', 'id_ID').format(date);

                return Dismissible(
                  key: Key(item['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: index == 0 && _expenseItems.length == 1
                          ? BorderRadius.circular(14)
                          : index == 0
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14),
                                )
                              : index == _expenseItems.length - 1
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(14),
                                      bottomRight: Radius.circular(14),
                                    )
                                  : BorderRadius.zero,
                    ),
                    child:
                        const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Pengeluaran'),
                        content: Text(
                            'Hapus "${item['name']}" (${_formatCurrency(item['amount'])})?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _deleteExpense(item['id']),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getCategoryIcon(item['category']),
                            color: const Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name & category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: smBold.copyWith(color: textPrimary),
                              ),
                              Text(
                                '${item['category']} • $formattedDate',
                                style:
                                    xsRegular.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        // Amount
                        Text(
                          '- ${_formatCurrency(item['amount'])}',
                          style:
                              smBold.copyWith(color: const Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'detergen':
        return Icons.local_laundry_service_rounded;
      case 'listrik':
        return Icons.bolt_rounded;
      case 'air':
        return Icons.water_drop_rounded;
      case 'gaji':
        return Icons.people_rounded;
      case 'sewa':
        return Icons.home_rounded;
      case 'transportasi':
        return Icons.local_shipping_rounded;
      case 'peralatan':
        return Icons.build_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  // ===== ADD EXPENSE DIALOG =====
  void _showAddExpenseDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Detergen';

    final categories = [
      'Detergen',
      'Listrik',
      'Air',
      'Gaji',
      'Sewa',
      'Transportasi',
      'Peralatan',
      'Lainnya',
    ];

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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Tambah Pengeluaran', style: mBold),
                  const SizedBox(height: 20),

                  // Nama pengeluaran
                  Text('Nama', style: smBold.copyWith(color: textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Detergen Bubuk 5kg',
                      hintStyle: sRegular.copyWith(color: Colors.grey[400]),
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
                        borderSide: const BorderSide(color: Color(0xFF2F5FE3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kategori
                  Text('Kategori', style: smBold.copyWith(color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => selectedCategory = cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2F5FE3).withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2F5FE3)
                                  : gray200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(cat),
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF2F5FE3)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: xsRegular.copyWith(
                                  color: isSelected
                                      ? const Color(0xFF2F5FE3)
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Jumlah
                  Text('Jumlah (Rp)',
                      style: smBold.copyWith(color: textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 150000',
                      hintStyle: sRegular.copyWith(color: Colors.grey[400]),
                      prefixText: 'Rp ',
                      prefixStyle: smBold.copyWith(color: textPrimary),
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
                        borderSide: const BorderSide(color: Color(0xFF2F5FE3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catatan (optional)
                  Text('Catatan (opsional)',
                      style: smBold.copyWith(color: textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Catatan tambahan...',
                      hintStyle: sRegular.copyWith(color: Colors.grey[400]),
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
                        borderSide: const BorderSide(color: Color(0xFF2F5FE3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final amountText = amountController.text.trim();
                        if (name.isEmpty || amountText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama dan jumlah harus diisi'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final amount = int.tryParse(amountText) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jumlah harus lebih dari 0'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _addExpense(
                          name: name,
                          category: selectedCategory,
                          amount: amount,
                          note: noteController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F5FE3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Simpan Pengeluaran',
                        style:
                            smBold.copyWith(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== SINGLE DOWNLOAD PDF BUTTON =====
  Widget _buildDownloadPdfButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download Laporan Keuangan PDF — Coming soon'),
              backgroundColor: Color(0xFF2F5FE3),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F5FE3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF2F5FE3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Laporan Keuangan',
                    style: smBold.copyWith(color: textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemasukan, pengeluaran & laba bersih',
                    style: xsRegular.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
