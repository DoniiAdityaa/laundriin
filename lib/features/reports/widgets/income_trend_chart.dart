import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class IncomeTrendChart extends StatefulWidget {
  final String period; // 'week' or 'month'

  const IncomeTrendChart({
    super.key,
    required this.period,
  });

  @override
  State<IncomeTrendChart> createState() => _IncomeTrendChartState();
}

class _IncomeTrendChartState extends State<IncomeTrendChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<int, int> _dailyIncome = {}; // day -> income
  StreamSubscription? _ordersSubscription;

  final List<Color> gradientColors = [
    const Color(0xFF2F5FE3).withOpacity(0.7),
    const Color(0xFF2F5FE3),
  ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void didUpdateWidget(IncomeTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      // Period changed, refresh listener
      _ordersSubscription?.cancel();
      _setupRealtimeListener();
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    try {
      final now = DateTime.now();
      late final DateTime startDate;

      if (widget.period == 'week') {
        // Start of this week (Monday)
        startDate = now.subtract(Duration(days: now.weekday - 1));
      } else {
        // Start of this month
        startDate = DateTime(now.year, now.month, 1);
      }

      final startOfDay =
          DateTime(startDate.year, startDate.month, startDate.day);

      _ordersSubscription = _firestore
          .collection('shops')
          .doc(_userId)
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('status', whereIn: ['completed', 'process'])
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              _updateDailyIncome(snapshot, startDate);
            }
          }, onError: (e) {
            print('[INCOME_CHART] Error: $e');
          });

      print('[INCOME_CHART] ✅ Listener setup for ${widget.period}');
    } catch (e) {
      print('[INCOME_CHART] ❌ Error setup listener: $e');
    }
  }

  void _updateDailyIncome(QuerySnapshot snapshot, DateTime startDate) {
    Map<int, int> tempIncome = {};

    // Initialize all days with 0
    final daysInPeriod = widget.period == 'week' ? 7 : 30;
    for (int i = 0; i < daysInPeriod; i++) {
      tempIncome[i] = 0;
    }

    // Calculate start of day
    final startOfPeriod =
        DateTime(startDate.year, startDate.month, startDate.day);

    // Sum income per day from Firestore orders
    for (var doc in snapshot.docs) {
      final totalPrice = doc['totalPrice'] as int? ?? 0;
      final createdAt = doc['createdAt'] as Timestamp?;

      if (createdAt != null) {
        final orderDate = createdAt.toDate();
        final orderDateOnly =
            DateTime(orderDate.year, orderDate.month, orderDate.day);
        final dayDiff = orderDateOnly.difference(startOfPeriod).inDays;

        if (dayDiff >= 0 && dayDiff < daysInPeriod) {
          tempIncome[dayDiff] = (tempIncome[dayDiff] ?? 0) + totalPrice;
        }
      }
    }

    setState(() {
      _dailyIncome = tempIncome;
    });

    print('[INCOME_CHART] ✅ Daily income updated: $_dailyIncome');
  }

  /// Get max value from list of FlSpot
  double _getMaxValue(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    return spots.fold<double>(0, (max, spot) => spot.y > max ? spot.y : max);
  }

  /// Round up to beautiful number
  double _roundUpToBeautiful(double value) {
    if (value <= 0) return 0;

    final beautifulNumbers = [
      50000.0,
      100000.0,
      150000.0,
      200000.0,
      250000.0,
      300000.0,
      500000.0,
      1000000.0,
      1500000.0,
      2000000.0,
      2500000.0,
      3000000.0,
      5000000.0
    ];

    for (var num in beautifulNumbers) {
      if (value <= num) return num;
    }
    return value;
  }

  /// Format number to Rupiah format
  String _formatRupiah(double value) {
    final val = value.toInt();
    if (val == 0) return 'Rp 0';
    if (val < 1000000) {
      final k = val ~/ 1000;
      return 'Rp ${k}K';
    } else if (val < 1000000000) {
      final m = val / 1000000;
      if (m == m.toInt()) {
        return 'Rp ${m.toInt()}M';
      } else {
        return 'Rp ${m.toStringAsFixed(1)}M';
      }
    }
    return 'Rp ${(val / 1000000).toStringAsFixed(0)}M';
  }

  /// Calculate chart scale and intervals
  Map<String, dynamic> _calculateChartScale(List<FlSpot> spots) {
    final maxValue = _getMaxValue(spots);
    final roundedMax = _roundUpToBeautiful(maxValue);
    var interval = roundedMax / 6;

    // Ensure interval is never 0
    if (interval <= 0) {
      interval = 50000.0; // Must be double!
    }

    final labels = <String>[];
    for (int i = 0; i <= 6; i++) {
      labels.add(_formatRupiah(interval * i));
    }

    return {
      'maxY': roundedMax > 0 ? roundedMax : 300000.0,
      'interval': interval,
      'labels': labels,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 8,
          left: 8,
          top: 12,
          bottom: 8,
        ),
        child: LineChart(
          _buildChartData(),
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    if (widget.period == 'week') {
      return _buildWeekChart();
    } else {
      return _buildMonthChart();
    }
  }

  // ===== WEEK CHART =====
  LineChartData _buildWeekChart() {
    // Build week spots from real Firestore data
    final weekSpots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      final income = _dailyIncome[i] ?? 0;
      weekSpots.add(FlSpot(i.toDouble(), income.toDouble()));
    }

    // Calculate scale based on data
    final scale = _calculateChartScale(weekSpots);
    final maxY = scale['maxY'] as double;
    final interval = scale['interval'] as double;
    final labels = scale['labels'] as List<String>;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: interval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!.withOpacity(0.5),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!.withOpacity(0.3),
            strokeWidth: 0.8,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameSize: 16,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final index = value.toInt();
              if (index >= 0 && index < days.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    days[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameSize: 16,
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            getTitlesWidget: (value, meta) {
              // Find matching label for this value
              final index = (value / interval).round();
              if (index >= 0 && index < labels.length) {
                return Text(
                  labels[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.left,
                );
              }
              return const SizedBox();
            },
            reservedSize: 50,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          preventCurveOverShooting: true,
          spots: weekSpots,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.2))
                  .toList(),
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final textColor = Colors.white;
              return LineTooltipItem(
                _formatRupiah(touchedSpot.y),
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  // ===== MONTH CHART =====
  LineChartData _buildMonthChart() {
    // Build month spots from real Firestore data (30 days)
    final monthSpots = <FlSpot>[];
    for (int i = 0; i < 30; i++) {
      final income = _dailyIncome[i] ?? 0;
      monthSpots.add(FlSpot(i.toDouble(), income.toDouble()));
    }

    // Calculate scale based on data
    final scale = _calculateChartScale(monthSpots);
    final maxY = scale['maxY'] as double;
    final interval = scale['interval'] as double;
    final labels = scale['labels'] as List<String>;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: interval,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!.withOpacity(0.5),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!.withOpacity(0.3),
            strokeWidth: 0.8,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameSize: 16,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              // Smart label: show every 5 days
              final index = value.toInt();
              if (index % 5 == 0 || index == 29) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameSize: 16,
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            getTitlesWidget: (value, meta) {
              // Find matching label for this value
              final index = (value / interval).round();
              if (index >= 0 && index < labels.length) {
                return Text(
                  labels[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.left,
                );
              }
              return const SizedBox();
            },
            reservedSize: 50,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      minX: 0,
      maxX: 29,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          preventCurveOverShooting: true,
          spots: monthSpots,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.15))
                  .toList(),
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final day = touchedSpot.x.toInt() + 1;
              final textColor = Colors.white;
              return LineTooltipItem(
                'Day $day: ${_formatRupiah(touchedSpot.y)}',
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
