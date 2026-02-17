import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:laundriin/ui/typography.dart';

class ServiceDistributionChart extends StatefulWidget {
  final String period; // 'week' or 'month'

  const ServiceDistributionChart({
    super.key,
    required this.period,
  });

  @override
  State<ServiceDistributionChart> createState() =>
      _ServiceDistributionChartState();
}

class _ServiceDistributionChartState extends State<ServiceDistributionChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, int> _serviceCount = {};
  StreamSubscription? _ordersSubscription;
  int _touchedIndex = -1;

  // 5 services with colors
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Cuci Komplit',
      'color': const Color(0xFF4F7DF3), // Soft Primary Blue
    },
    {
      'name': 'Cuci Kering',
      'color': const Color(0xFF9CA3AF), // Soft Gray
    },
    {
      'name': 'Setrika',
      'color': const Color(0xFF7AA2FF), // Soft Light Blue
    },
    {
      'name': 'Setrika Uap',
      'color': const Color(0xFFA5BFFF), // Pastel Blue
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void didUpdateWidget(ServiceDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      // Period changed, update listener
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
              _updateServiceCount(snapshot);
            }
          }, onError: (e) {
            print('[PIE_CHART] Error: $e');
          });

      print('[PIE_CHART] ✅ Listener setup for ${widget.period}');
    } catch (e) {
      print('[PIE_CHART] ❌ Error setup listener: $e');
    }
  }

  void _updateServiceCount(QuerySnapshot snapshot) {
    Map<String, int> tempCount = {
      'Cuci Komplit': 0,
      'Cuci Kering': 0,
      'Setrika': 0,
      'Setrika Uap': 0,
    };

    for (var doc in snapshot.docs) {
      final serviceType = doc['serviceType'] as String? ?? 'Cuci Komplit';

      // Map category/serviceType to our services
      String mappedService = 'Cuci Komplit';

      final lowerType = serviceType.toLowerCase();

      // Check for Setrika Uap (steamIroning, steam ironing, steam_ironing)
      if (lowerType.contains('steam')) {
        mappedService = 'Setrika Uap';
      }
      // Check for Cuci Kering (dry wash, drywash, dry_wash)
      else if (lowerType.contains('dry')) {
        mappedService = 'Cuci Kering';
      }
      // Check for Setrika (ironing, setrika)
      else if (lowerType.contains('iron') || lowerType.contains('setrika')) {
        mappedService = 'Setrika';
      }
      // Default: Cuci Komplit (wash, kiloan, laundry, atau default)
      else {
        mappedService = 'Cuci Komplit';
      }

      if (tempCount.containsKey(mappedService)) {
        tempCount[mappedService] = tempCount[mappedService]! + 1;
      }
    }

    setState(() {
      _serviceCount = tempCount;
    });

    print('[PIE_CHART] Updated counts: $_serviceCount');
  }

  @override
  Widget build(BuildContext context) {
    final total = _serviceCount.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Belum ada data layanan',
            style: sRegular.copyWith(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          const SizedBox(height: 18),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: _showingSections(total),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._services.map((service) {
                final serviceName = service['name'] as String;
                final count = _serviceCount[serviceName] ?? 0;
                final percentage = total > 0
                    ? (count / total * 100).toStringAsFixed(1)
                    : '0.0';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: service['color'] as Color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: xsRegular.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$count ($percentage%)',
                            style: xsRegular.copyWith(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(int total) {
    return List.generate(_services.length, (i) {
      final service = _services[i];
      final serviceName = service['name'] as String;
      final count = _serviceCount[serviceName] ?? 0;
      final value = total > 0 ? (count / total * 100) : 0.0;

      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 80.0 : 70.0;

      return PieChartSectionData(
        color: service['color'] as Color,
        value: value > 0 ? value : 0.1,
        title: value > 0 ? '${value.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }
}
