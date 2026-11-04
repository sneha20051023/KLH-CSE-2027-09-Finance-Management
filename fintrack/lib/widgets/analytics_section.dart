import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Comprehensive Financial Analytics section with interactive BarChart,
/// LineChart, Category insights, and Summary KPI metrics.
class AnalyticsSection extends StatefulWidget {
  const AnalyticsSection({super.key});

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  String _timeRange = 'Monthly'; // Weekly, Monthly, Yearly

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final allTx = txProvider.allTransactions;

    final income = txProvider.totalIncome;
    final expenses = txProvider.totalExpenses;
    final savings = income - expenses;
    final txCount = txProvider.transactions.length;

    // Highest spending category
    String highestCat = 'None';
    double highestAmount = 0.0;
    txProvider.categoryTotals.forEach((cat, amt) {
      if (amt > highestAmount) {
        highestAmount = amt;
        highestCat = cat;
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Financial Analytics',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              // Time Range Selector Chips
              Row(
                children: ['Weekly', 'Monthly', 'Yearly'].map((range) {
                  final isSelected = _timeRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => setState(() => _timeRange = range),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          range,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4 Summary Metrics KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Net Savings',
                  value: formatCurrency(savings),
                  icon: Icons.savings_rounded,
                  color: savings >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: 'Top Expense',
                  value: highestCat,
                  subtitle: highestAmount > 0 ? formatCurrency(highestAmount) : null,
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Total Transactions',
                  value: '$txCount',
                  icon: Icons.tag_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: 'Savings Rate',
                  value: income > 0
                      ? '${((savings / income) * 100).clamp(0, 100).toStringAsFixed(0)}%'
                      : '0%',
                  icon: Icons.pie_chart_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 1. Bar Chart: Income vs Expenses
          Text(
            'Income vs. Expenses',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildLegend(AppColors.income, 'Income'),
              const SizedBox(width: 14),
              _buildLegend(AppColors.expense, 'Expenses'),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (income > expenses ? income : expenses) * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.text,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Income' : 'Expense';
                      return BarTooltipItem(
                        '$label: ${formatCurrency(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final m = txProvider.selectedMonth;
                        final prevM = m == 1 ? 12 : m - 1;
                        if (val.toInt() == 0) {
                          return Text(getMonthName(prevM).substring(0, 3), style: const TextStyle(fontSize: 10));
                        }
                        if (val.toInt() == 1) {
                          return Text(getMonthName(m).substring(0, 3), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  // Previous Month
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: txProvider.previousMonthIncome,
                        color: AppColors.income.withOpacity(0.7),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: txProvider.previousMonthExpenses,
                        color: AppColors.expense.withOpacity(0.7),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  // Current Month
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: AppColors.income,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expenses,
                        color: AppColors.expense,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Line Chart: Weekly Spending Trend
          Text(
            'Weekly Spending Trend',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Expense trend over the weeks of the month',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 180,
            child: LineChart(
              _buildWeeklyTrendData(allTx, txProvider.selectedMonth, txProvider.selectedYear),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildWeeklyTrendData(
    List<TransactionModel> allTx,
    int month,
    int year,
  ) {
    // Group expenses into 4 weeks
    double w1 = 0, w2 = 0, w3 = 0, w4 = 0;

    for (final tx in allTx) {
      if (tx.type == TransactionType.expense &&
          tx.date.month == month &&
          tx.date.year == year) {
        final d = tx.date.day;
        if (d <= 7) {
          w1 += tx.amount;
        } else if (d <= 14) {
          w2 += tx.amount;
        } else if (d <= 21) {
          w3 += tx.amount;
        } else {
          w4 += tx.amount;
        }
      }
    }

    final maxVal = [w1, w2, w3, w4].reduce((a, b) => a > b ? a : b);
    final ceiling = maxVal > 0 ? maxVal * 1.3 : 1000.0;

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              switch (val.toInt()) {
                case 1:
                  return const Text('W1', style: TextStyle(fontSize: 10));
                case 2:
                  return const Text('W2', style: TextStyle(fontSize: 10));
                case 3:
                  return const Text('W3', style: TextStyle(fontSize: 10));
                case 4:
                  return const Text('W4', style: TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0.8,
      maxX: 4.2,
      minY: 0,
      maxY: ceiling,
      lineBarsData: [
        LineChartBarData(
          spots: [
            FlSpot(1, w1),
            FlSpot(2, w2),
            FlSpot(3, w3),
            FlSpot(4, w4),
          ],
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 1.5, strokeColor: Colors.white),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.primary.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }
}

