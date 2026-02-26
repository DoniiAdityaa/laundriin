import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
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
  String selectedPeriod = 'day'; // day or week or month
  DateTime _selectedDate = DateTime.now();

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

  // Top customers state
  List<Map<String, dynamic>> _topCustomers = [];
  StreamSubscription? _topCustomersSubscription;

  // Pending orders state
  List<Map<String, dynamic>> _pendingOrders = [];
  StreamSubscription? _pendingOrdersSubscription;

  @override
  void initState() {
    super.initState();
    _setupIncomeListener();
    _setupExpenseListener();
    _setupTopCustomersListener();
    _setupPendingOrdersListener();
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
    _topCustomersSubscription?.cancel();
    _pendingOrdersSubscription?.cancel();
    super.dispose();
  }

  void _setupIncomeListener() {
    try {
      final ref = _selectedDate;
      late final DateTime currentStart, previousStart;

      if (selectedPeriod == 'day') {
        // Hari yang dipilih
        currentStart = DateTime(ref.year, ref.month, ref.day);
        // Hari sebelumnya
        final yesterday = currentStart.subtract(const Duration(days: 1));
        previousStart =
            DateTime(yesterday.year, yesterday.month, yesterday.day);
      } else if (selectedPeriod == 'week') {
        // Awal minggu yang dipilih (Senin)
        final weekStart = ref.subtract(Duration(days: ref.weekday - 1));
        currentStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

        // Minggu sebelumnya
        previousStart = currentStart.subtract(const Duration(days: 7));
      } else {
        // Bulan yang dipilih
        currentStart = DateTime(ref.year, ref.month, 1);

        // Bulan sebelumnya
        final prevMonth = currentStart.subtract(const Duration(days: 1));
        previousStart = DateTime(prevMonth.year, prevMonth.month, 1);
      }

      final currentStartOfDay =
          DateTime(currentStart.year, currentStart.month, currentStart.day);
      final previousStartOfDay =
          DateTime(previousStart.year, previousStart.month, previousStart.day);

      // Tentukan batas akhir periode
      late final DateTime currentEndOfDay;
      if (selectedPeriod == 'day') {
        currentEndOfDay = currentStartOfDay.add(const Duration(days: 1));
      } else if (selectedPeriod == 'week') {
        currentEndOfDay = currentStartOfDay.add(const Duration(days: 7));
      } else {
        currentEndOfDay =
            DateTime(currentStartOfDay.year, currentStartOfDay.month + 1, 1);
      }

      _incomeSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          _calculateIncome(
              snapshot, currentStartOfDay, previousStartOfDay, currentEndOfDay);
        }
      }, onError: (e) {
        print('[INCOME] Error: $e');
      });

      print('[INCOME] ✅ Listener setup for ${selectedPeriod}');
    } catch (e) {
      print('[INCOME] ❌ Error setup listener: $e');
    }
  }

  void _calculateIncome(QuerySnapshot snapshot, DateTime currentStart,
      DateTime previousStart, DateTime currentEnd) {
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

        if ((orderDate.isAfter(currentStart) ||
                orderDate.isAtSameMomentAs(currentStart)) &&
            orderDate.isBefore(currentEnd)) {
          currentIncome += totalPrice;
          currentOrders++;
        } else if ((orderDate.isAfter(previousStart) ||
                orderDate.isAtSameMomentAs(previousStart)) &&
            orderDate.isBefore(currentStart)) {
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
                    const SizedBox(height: 12),
                    // ===== PERIOD NAVIGATION =====
                    _buildPeriodNavigation(),
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

                    // 3. Income Trend Chart (hide for daily)
                    if (selectedPeriod != 'day') ...[
                      _buildIncomeTrend(),
                      const SizedBox(height: 20),
                    ],

                    // 4. Service Distribution Chart
                    _buildServiceDistribution(),
                    const SizedBox(height: 20),

                    // 5. Top Customers (hide for daily)
                    if (selectedPeriod != 'day') ...[
                      _buildTopCustomers(),
                      const SizedBox(height: 20),
                    ],

                    // 6. Pending Orders Alert
                    _buildPendingOrdersAlert(),
                    const SizedBox(height: 20),

                    // 7. Download PDF (Single Button)
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
          _buildPeriodButton('Hari', 'day'),
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
          setState(() {
            selectedPeriod = value;
            _selectedDate = DateTime.now(); // Reset ke hari ini saat ganti mode
          });
          // Refresh listeners saat period berubah
          _incomeSubscription?.cancel();
          _setupIncomeListener();
          _expenseSubscription?.cancel();
          _setupExpenseListener();
          _topCustomersSubscription?.cancel();
          _setupTopCustomersListener();
          _pendingOrdersSubscription?.cancel();
          _setupPendingOrdersListener();
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

  // ===== PERIOD NAVIGATION =====
  Widget _buildPeriodNavigation() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    // Cek apakah sudah di periode terkini (disable tombol →)
    bool isAtCurrent;
    if (selectedPeriod == 'day') {
      isAtCurrent = selected.isAtSameMomentAs(today);
    } else if (selectedPeriod == 'week') {
      final currentWeekStart =
          today.subtract(Duration(days: today.weekday - 1));
      final selectedWeekStart =
          selected.subtract(Duration(days: selected.weekday - 1));
      isAtCurrent = selectedWeekStart.isAtSameMomentAs(currentWeekStart);
    } else {
      isAtCurrent =
          selected.year == today.year && selected.month == today.month;
    }

    return Row(
      children: [
        // Tombol ←
        _navArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => _navigatePeriod(-1),
        ),
        // Label (tap untuk buka DatePicker)
        Expanded(
          child: GestureDetector(
            onTap: _openDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                _getNavigationLabel(),
                style: smSemiBold.copyWith(
                  color: textPrimary,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ),
        // Tombol →
        _navArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: isAtCurrent ? null : () => _navigatePeriod(1),
          disabled: isAtCurrent,
        ),
      ],
    );
  }

  Widget _navArrowButton({
    required IconData icon,
    VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey[100] : white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: disabled ? Colors.grey[200]! : gray200),
        ),
        child: Icon(
          icon,
          size: 20,
          color: disabled ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  void _navigatePeriod(int direction) {
    setState(() {
      if (selectedPeriod == 'day') {
        _selectedDate = _selectedDate.add(Duration(days: direction));
      } else if (selectedPeriod == 'week') {
        _selectedDate = _selectedDate.add(Duration(days: 7 * direction));
      } else {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + direction,
          1,
        );
      }
    });
    // Refresh listeners
    _incomeSubscription?.cancel();
    _setupIncomeListener();
    _expenseSubscription?.cancel();
    _setupExpenseListener();
    _topCustomersSubscription?.cancel();
    _setupTopCustomersListener();
    _pendingOrdersSubscription?.cancel();
    _setupPendingOrdersListener();
  }

  Future<void> _openDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: blue500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _incomeSubscription?.cancel();
      _setupIncomeListener();
      _expenseSubscription?.cancel();
      _setupExpenseListener();
      _topCustomersSubscription?.cancel();
      _setupTopCustomersListener();
      _pendingOrdersSubscription?.cancel();
      _setupPendingOrdersListener();
    }
  }

  String _getNavigationLabel() {
    final d = _selectedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(d.year, d.month, d.day);

    switch (selectedPeriod) {
      case 'day':
        if (selected.isAtSameMomentAs(today)) {
          return 'Hari ini, ${d.day} ${_getMonthName(d.month)} ${d.year}';
        }
        final yesterday = today.subtract(const Duration(days: 1));
        if (selected.isAtSameMomentAs(yesterday)) {
          return 'Kemarin, ${d.day} ${_getMonthName(d.month)} ${d.year}';
        }
        // Nama hari
        const dayNames = [
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat',
          'Sabtu',
          'Minggu'
        ];
        return '${dayNames[d.weekday - 1]}, ${d.day} ${_getMonthName(d.month)} ${d.year}';

      case 'week':
        final weekStart = d.subtract(Duration(days: d.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final currentWeekStart =
            today.subtract(Duration(days: today.weekday - 1));
        final prefix = weekStart.isAtSameMomentAs(currentWeekStart)
            ? 'Minggu ini'
            : 'Minggu';
        if (weekStart.month == weekEnd.month) {
          return '$prefix, ${weekStart.day}-${weekEnd.day} ${_getMonthName(weekEnd.month)}';
        }
        return '$prefix, ${weekStart.day} ${_getMonthName(weekStart.month)} - ${weekEnd.day} ${_getMonthName(weekEnd.month)}';

      case 'month':
      default:
        final isCurrentMonth = d.year == today.year && d.month == today.month;
        final prefix = isCurrentMonth ? 'Bulan ini' : '';
        final label = '${_getMonthName(d.month)} ${d.year}';
        return isCurrentMonth ? '$prefix, $label' : label;
    }
  }

  // ===== EXPENSE LISTENER =====
  void _setupExpenseListener() {
    try {
      final ref = _selectedDate;
      late final DateTime currentStart;
      late final DateTime currentEnd;

      if (selectedPeriod == 'day') {
        currentStart = DateTime(ref.year, ref.month, ref.day);
        currentEnd = currentStart.add(const Duration(days: 1));
      } else if (selectedPeriod == 'week') {
        currentStart = DateTime(ref.year, ref.month, ref.day)
            .subtract(Duration(days: ref.weekday - 1));
        currentEnd = currentStart.add(const Duration(days: 7));
      } else {
        currentStart = DateTime(ref.year, ref.month, 1);
        currentEnd = DateTime(ref.year, ref.month + 1, 1);
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

              if ((expenseDate.isAfter(currentStartOfDay) ||
                      expenseDate.isAtSameMomentAs(currentStartOfDay)) &&
                  expenseDate.isBefore(currentEnd)) {
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

  // ===== TOP CUSTOMERS LISTENER =====
  void _setupTopCustomersListener() {
    try {
      final ref = _selectedDate;
      late final DateTime currentStart;
      late final DateTime currentEnd;

      if (selectedPeriod == 'day') {
        currentStart = DateTime(ref.year, ref.month, ref.day);
        currentEnd = currentStart.add(const Duration(days: 1));
      } else if (selectedPeriod == 'week') {
        currentStart = DateTime(ref.year, ref.month, ref.day)
            .subtract(Duration(days: ref.weekday - 1));
        currentEnd = currentStart.add(const Duration(days: 7));
      } else {
        currentStart = DateTime(ref.year, ref.month, 1);
        currentEnd = DateTime(ref.year, ref.month + 1, 1);
      }

      _topCustomersSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          // Group by customerName
          final Map<String, Map<String, dynamic>> customerMap = {};

          for (var doc in snapshot.docs) {
            final createdAt = doc['createdAt'] as Timestamp?;
            if (createdAt == null) continue;

            final orderDate = createdAt.toDate();
            if (orderDate.isBefore(currentStart) ||
                !orderDate.isBefore(currentEnd)) continue;

            final name = doc['customerName'] as String? ?? 'Unknown';
            final phone = doc['customerPhone'] as String? ?? '';
            final price = doc['totalPrice'] as int? ?? 0;

            if (customerMap.containsKey(name)) {
              customerMap[name]!['orders'] =
                  (customerMap[name]!['orders'] as int) + 1;
              customerMap[name]!['amount'] =
                  (customerMap[name]!['amount'] as int) + price;
            } else {
              customerMap[name] = {
                'name': name,
                'phone': phone,
                'orders': 1,
                'amount': price,
              };
            }
          }

          // Sort by order count descending, then by amount
          final sorted = customerMap.values.toList()
            ..sort((a, b) {
              final cmp = (b['orders'] as int).compareTo(a['orders'] as int);
              if (cmp != 0) return cmp;
              return (b['amount'] as int).compareTo(a['amount'] as int);
            });

          setState(() {
            _topCustomers = sorted.take(3).toList();
          });
        }
      }, onError: (e) {
        print('[TOP CUSTOMERS] Error: $e');
      });

      print('[TOP CUSTOMERS] ✅ Listener setup for $selectedPeriod');
    } catch (e) {
      print('[TOP CUSTOMERS] ❌ Error setup listener: $e');
    }
  }

  // ===== PENDING ORDERS LISTENER =====
  void _setupPendingOrdersListener() {
    _pendingOrdersSubscription?.cancel();
    try {
      _pendingOrdersSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .where('status', whereIn: ['pending', 'process'])
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              final now = DateTime.now();
              List<Map<String, dynamic>> orders = [];

              for (var doc in snapshot.docs) {
                final createdAt = doc['createdAt'] as Timestamp?;
                if (createdAt == null) continue;

                final orderDate = createdAt.toDate();
                final daysOverdue = now.difference(orderDate).inDays;

                orders.add({
                  'id': doc.id,
                  'orderId': doc['orderId'] ?? doc.id,
                  'customerName': doc['customerName'] ?? 'Unknown',
                  'customerPhone': doc['customerPhone'] ?? '',
                  'totalPrice': doc['totalPrice'] as int? ?? 0,
                  'status': doc['status'] ?? 'pending',
                  'daysOverdue': daysOverdue,
                  'createdAt': orderDate,
                });
              }

              // Sort: paling lama (overdue terbesar) di atas
              orders.sort((a, b) =>
                  (b['daysOverdue'] as int).compareTo(a['daysOverdue'] as int));

              setState(() {
                _pendingOrders = orders;
              });
            }
          }, onError: (e) {
            print('[PENDING ORDERS] Error: $e');
          });

      print('[PENDING ORDERS] ✅ Listener setup');
    } catch (e) {
      print('[PENDING ORDERS] ❌ Error setup listener: $e');
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

  // ===== UPDATE EXPENSE =====
  Future<void> _updateExpense({
    required String expenseId,
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
          .doc(expenseId)
          .update({
        'name': name,
        'category': category,
        'amount': amount,
        'note': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil diperbarui'),
            backgroundColor: Color(0xFF1F8F5F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui: $e'),
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
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF1F8F5F).withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(6),
            //   ),
            //   // child: const Text(
            //   //   '+12.5% this week',
            //   //   style: TextStyle(
            //   //     fontSize: 11,
            //   //     fontWeight: FontWeight.bold,
            //   //     color: Color(0xFF1F8F5F),
            //   //   ),
            //   // ),
            // ),
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
          child: IncomeTrendChart(
              period: selectedPeriod, referenceDate: _selectedDate),
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
          child: ServiceDistributionChart(
              period: selectedPeriod, referenceDate: _selectedDate),
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
    if (_topCustomers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pelanggan Terbanyak',
            style: mBold,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 40, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text(
                  'Belum ada data pelanggan',
                  style: smRegular.copyWith(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pelanggan Terbanyak',
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
            children: List.generate(_topCustomers.length, (index) {
              final customer = _topCustomers[index];
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

  // // ===== 6. STATUS ORDERS SUMMARY =====
  // Widget _buildStatusOrdersSummary() {
  //   // Dummy data - replace dengan Firebase nanti
  //   final statusData = [
  //     {
  //       'label': 'Selesai',
  //       'count': 30,
  //       'icon': Icons.check_circle_rounded,
  //       'color': const Color(0xFF1F8F5F),
  //       'bgColor': const Color(0xFF1F8F5F).withOpacity(0.1),
  //     },
  //     {
  //       'label': 'Proses',
  //       'count': 12,
  //       'icon': Icons.autorenew_rounded,
  //       'color': const Color(0xFFF59E0B),
  //       'bgColor': const Color(0xFFF59E0B).withOpacity(0.1),
  //     },
  //     {
  //       'label': 'Pending',
  //       'count': 5,
  //       'icon': Icons.schedule_rounded,
  //       'color': const Color(0xFF3B82F6),
  //       'bgColor': const Color(0xFF3B82F6).withOpacity(0.1),
  //     },
  //     {
  //       'label': 'Batal',
  //       'count': 2,
  //       'icon': Icons.cancel_rounded,
  //       'color': Colors.red,
  //       'bgColor': Colors.red.withOpacity(0.1),
  //     },
  //   ];

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Status Pesanan',
  //         style: mBold,
  //       ),
  //       const SizedBox(height: 12),
  //       GridView.count(
  //         crossAxisCount: 2,
  //         crossAxisSpacing: 12,
  //         mainAxisSpacing: 12,
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         children: statusData.map((status) {
  //           return Container(
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(14),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.06),
  //                   blurRadius: 8,
  //                   offset: const Offset(0, 2),
  //                 )
  //               ],
  //             ),
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Container(
  //                   width: 48,
  //                   height: 48,
  //                   decoration: BoxDecoration(
  //                     color: status['bgColor'] as Color,
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Icon(
  //                     status['icon'] as IconData,
  //                     color: status['color'] as Color,
  //                     size: 24,
  //                   ),
  //                 ),
  //                 Column(
  //                   children: [
  //                     Text(
  //                       (status['count'] as int).toString(),
  //                       style: const TextStyle(
  //                         fontSize: 24,
  //                         fontWeight: FontWeight.bold,
  //                         color: Color(0xFF111827),
  //                       ),
  //                     ),
  //                     Text(
  //                       status['label'] as String,
  //                       style: xsRegular.copyWith(color: Colors.grey[600]),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ],
  //   );
  // }

  // ===== 7. PENDING ORDERS ALERT =====
  Widget _buildPendingOrdersAlert() {
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
            if (_pendingOrders.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_pendingOrders.length} pesanan',
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
        if (_pendingOrders.isEmpty)
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
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/check-2.png',
                    width: 40,
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
              itemCount: _pendingOrders.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final order = _pendingOrders[index];
                final daysOverdue = order['daysOverdue'] as int;
                final isUrgent = daysOverdue > 2;
                final status = order['status'] as String;
                final statusLabel =
                    status == 'process' ? 'Diproses' : 'Pending';

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
                          isUrgent
                              ? Icons.warning_rounded
                              : Icons.schedule_rounded,
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
                              '$statusLabel • $daysOverdue hari lalu',
                              style:
                                  xsRegular.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Text(
                        _formatCurrency(order['totalPrice'] as int),
                        style: smBold.copyWith(
                          color: isUrgent ? Colors.red : Colors.orange,
                        ),
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
            GestureDetector(
              onTap: () => _showAddExpenseDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: blue500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Tambah',
                      style: smBold.copyWith(color: Colors.white, fontSize: 13),
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
                    SvgPicture.asset(
                      'assets/svg/receipt-2.svg',
                      width: 35,
                      color: Colors.grey[500],
                    ),
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
                      barrierDismissible: true,
                      builder: (ctx) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                              Text('Hapus Pengeluaran', style: mBold),
                              const SizedBox(height: 12),
                              Text(
                                  'Hapus ${item['name']} ${_formatCurrency(item['amount'])}?',
                                  textAlign: TextAlign.center,
                                  style: sRegular.copyWith(color: textPrimary)),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFF3F4F6),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                          ),
                                          child: Text(
                                            'Tidak',
                                            style: smMedium.copyWith(
                                                color: iconButtonOutlined),
                                          ))),
                                  const SizedBox(width: 15),
                                  Expanded(
                                      child: ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: Text('Hapus',
                                        style: smMedium.copyWith(
                                            color: Colors.white)),
                                  )),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  onDismissed: (_) => _deleteExpense(item['id']),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: InkWell(
                      onTap: () => _showAddExpenseDialog(expense: item),
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
                                const SizedBox(height: 4),
                                Text(
                                  '${item['category']} • $formattedDate',
                                  style: xsRegular.copyWith(
                                      color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['note'] ?? '',
                                  style: xsRegular.copyWith(
                                      color: Colors.grey[400], fontSize: 11),
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
  void _showAddExpenseDialog({Map<String, dynamic>? expense}) {
    final nameController = TextEditingController(text: expense?['name'] ?? '');
    final amountController = TextEditingController(
        text: expense != null ? expense['amount'].toString() : '');
    final noteController = TextEditingController(text: expense?['note'] ?? '');
    String selectedCategory = expense?['category'] ?? 'Detergen';
    final bool isEdit = expense != null;

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
                  Text(
                    isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran',
                    style: mBold,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Nama pengeluaran
                  Text('Nama', style: smBold.copyWith(color: textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Listrik',
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
                        if (amount <= 0) return;

                        Navigator.pop(ctx);

                        if (isEdit) {
                          _updateExpense(
                            expenseId: expense['id'],
                            name: name,
                            category: selectedCategory,
                            amount: amount,
                            note: noteController.text.trim(),
                          );
                        } else {
                          _addExpense(
                            name: name,
                            category: selectedCategory,
                            amount: amount,
                            note: noteController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEdit ? 'Perbarui Pengeluaran' : 'Simpan Pengeluaran',
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
                child: Center(
                  child: SizedBox(
                    width: 25,
                    height: 25,
                    child: SvgPicture.asset(
                      'assets/svg/pdf.svg',
                      color: blue500,
                    ),
                  ),
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
    final d = _selectedDate;
    switch (selectedPeriod) {
      case 'day':
        return '${d.day} ${_getMonthName(d.month)} ${d.year}';
      case 'week':
        final startOfWeek = d.subtract(Duration(days: d.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${startOfWeek.day} - ${endOfWeek.day} ${_getMonthName(endOfWeek.month)}';
      case 'month':
      default:
        return '${_getMonthName(d.month)} ${d.year}';
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
