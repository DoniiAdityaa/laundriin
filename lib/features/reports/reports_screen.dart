import 'package:flutter/material.dart';
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
          // Top row: Label + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Income',
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F5FE3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF2F5FE3),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main amount
          const Text(
            'Rp 2.850.000',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F5FE3),
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 12),

          // Bottom: Orders completed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders Completed',
                    style: sRegular.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '28 orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F8F5F),
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F8F5F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1F8F5F),
                  size: 24,
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

  // ===== HELPER FUNCTION =====
  String _getPeriodLabel() {
    switch (selectedPeriod) {
      case 'week':
        return 'This Week';
      case 'month':
      default:
        return 'This Month';
    }
  }
}
