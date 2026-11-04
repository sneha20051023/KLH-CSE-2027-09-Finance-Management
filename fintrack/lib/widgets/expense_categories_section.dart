import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/category_model.dart';

/// Displays expense categories with an interactive Donut Chart
/// and category cards showing total spent and percentage of total expenses.
class ExpenseCategoriesSection extends StatefulWidget {
  const ExpenseCategoriesSection({super.key});

  @override
  State<ExpenseCategoriesSection> createState() => _ExpenseCategoriesSectionState();
}

class _ExpenseCategoriesSectionState extends State<ExpenseCategoriesSection> {
  int _touchedIndex = -1;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final categoryTotals = txProvider.categoryTotals;
    final totalExpenses = txProvider.totalExpenses;

    // Build category list with amounts and percentages
    final List<CategoryModel> activeCategories = [];
    final List<CategoryModel> zeroCategories = [];

    for (final defCat in CategoryModel.defaultCategories) {
      final spent = categoryTotals[defCat.name] ?? 0.0;
      final pct = totalExpenses > 0 ? (spent / totalExpenses) * 100 : 0.0;
      final cat = defCat.copyWith(totalSpent: spent, percentage: pct);
      if (spent > 0) {
        activeCategories.add(cat);
      } else {
        zeroCategories.add(cat);
      }
    }

    // Sort active categories by spending descending
    activeCategories.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    final displayCategories = [...activeCategories, ...zeroCategories];

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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: AppColors.roseAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Expense Categories',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (txProvider.filterCategory != 'All')
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCategory = null);
                    txProvider.setFilterCategory('All');
                  },
                  child: Text(
                    'Clear Filter',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Donut Chart or Empty State
          if (activeCategories.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No expenses recorded for this month',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
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
                      sectionsSpace: 3,
                      centerSpaceRadius: 65,
                      sections: activeCategories.asMap().entries.map((entry) {
                        final i = entry.key;
                        final cat = entry.value;
                        final isTouched = i == _touchedIndex;
                        final radius = isTouched ? 42.0 : 34.0;

                        return PieChartSectionData(
                          color: cat.color,
                          value: cat.totalSpent,
                          title: isTouched
                              ? '${cat.percentage.toStringAsFixed(0)}%'
                              : '',
                          radius: radius,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Center info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _touchedIndex != -1 &&
                                _touchedIndex < activeCategories.length
                            ? activeCategories[_touchedIndex].name
                            : 'Total Spent',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _touchedIndex != -1 &&
                                _touchedIndex < activeCategories.length
                            ? formatCurrency(activeCategories[_touchedIndex].totalSpent)
                            : formatCurrency(totalExpenses),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category Cards Grid / List
          Text(
            'Select a category to filter transactions:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayCategories.map((cat) {
              final isFiltered = txProvider.filterCategory == cat.name;

              return InkWell(
                onTap: () {
                  if (txProvider.filterCategory == cat.name) {
                    txProvider.setFilterCategory('All');
                    setState(() => _selectedCategory = null);
                  } else {
                    txProvider.setFilterCategory(cat.name);
                    setState(() => _selectedCategory = cat.name);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFiltered
                        ? AppColors.primary
                        : (cat.totalSpent > 0
                            ? AppColors.background
                            : AppColors.background.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFiltered
                          ? AppColors.primary
                          : (cat.totalSpent > 0
                              ? cat.color.withOpacity(0.3)
                              : AppColors.divider),
                      width: isFiltered ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isFiltered
                              ? Colors.white.withOpacity(0.2)
                              : cat.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icon,
                          size: 14,
                          color: isFiltered ? Colors.white : cat.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isFiltered ? Colors.white : AppColors.text,
                            ),
                          ),
                          if (cat.totalSpent > 0)
                            Text(
                              '${formatCompactCurrency(cat.totalSpent)} (${cat.percentage.toStringAsFixed(0)}%)',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isFiltered
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.textLight,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

