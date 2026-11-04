import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'set_budget_dialog.dart';

/// Budget Management section showing overall monthly budget progress
/// and individual category budgets with alert indicators.
class BudgetSection extends StatelessWidget {
  const BudgetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    final month = txProvider.selectedMonth;
    final year = txProvider.selectedYear;

    final overallBudget = budgetProvider.getOverallBudget(month, year);
    final allBudgets = budgetProvider.budgets
        .where((b) => b.month == month && b.year == year)
        .toList();
    final categoryBudgets = allBudgets.where((b) => b.category != 'Overall').toList();

    final totalSpent = txProvider.totalExpenses;
    final categoryTotals = txProvider.categoryTotals;

    final overallLimit = overallBudget?.monthlyLimit ?? 45000.0;
    final overallSpentPercent = overallLimit > 0
        ? ((totalSpent / overallLimit) * 100).clamp(0.0, 999.0)
        : 0.0;
    final overallRemaining = overallLimit - totalSpent;
    final isOverallExceeded = totalSpent > overallLimit;
    final isOverallNearLimit = totalSpent >= overallLimit * 0.8 && !isOverallExceeded;

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
                      Icons.track_changes_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Budget Management',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const SetBudgetDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Set Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Overall Monthly Budget Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOverallExceeded
                    ? [AppColors.expense.withOpacity(0.1), AppColors.expense.withOpacity(0.03)]
                    : (isOverallNearLimit
                        ? [AppColors.warning.withOpacity(0.12), AppColors.warning.withOpacity(0.04)]
                        : [AppColors.accent.withOpacity(0.8), AppColors.background]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOverallExceeded
                    ? AppColors.expense.withOpacity(0.4)
                    : (isOverallNearLimit
                        ? AppColors.warning.withOpacity(0.4)
                        : AppColors.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOverallExceeded
                              ? Icons.error_outline_rounded
                              : (isOverallNearLimit
                                  ? Icons.warning_amber_rounded
                                  : Icons.savings_outlined),
                          color: isOverallExceeded
                              ? AppColors.expense
                              : (isOverallNearLimit ? AppColors.warning : AppColors.primary),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Overall Monthly Budget',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => SetBudgetDialog(
                            initialBudget: overallBudget,
                            preselectedCategory: 'Overall',
                          ),
                        );
                      },
                      tooltip: 'Edit Overall Budget',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatCurrency(totalSpent)} spent',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isOverallExceeded ? AppColors.expense : AppColors.text,
                          ),
                        ),
                        Text(
                          'Limit: ${formatCurrency(overallLimit)}',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isOverallExceeded
                              ? 'Over by ${formatCurrency(totalSpent - overallLimit)}'
                              : '${formatCurrency(overallRemaining)} left',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isOverallExceeded ? AppColors.expense : AppColors.income,
                          ),
                        ),
                        Text(
                          '${overallSpentPercent.toStringAsFixed(1)}% utilized',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getBudgetStatusColor(overallSpentPercent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Overall progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (overallSpentPercent / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getBudgetStatusColor(overallSpentPercent),
                    ),
                  ),
                ),

                if (isOverallExceeded) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_rounded, size: 14, color: AppColors.expense),
                      const SizedBox(width: 4),
                      Text(
                        'Alert: You have exceeded your monthly budget!',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ] else if (isOverallNearLimit) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Warning: You have reached 80% of your monthly budget.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Category Budgets Header
          Text(
            'Category Budgets',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),

          // Category Budgets List
          if (categoryBudgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 40,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No category budgets set yet',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const SetBudgetDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Category Budget'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...categoryBudgets.map((b) {
              final spent = categoryTotals[b.category] ?? 0.0;
              final percent = b.percentUsed(spent);
              final isExceeded = b.isOverBudget(spent);
              final isNear = b.isNearLimit(spent) && !isExceeded;
              final catColor = getCategoryColor(b.category);
              final catIcon = getCategoryIcon(b.category);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExceeded
                        ? AppColors.expense.withOpacity(0.5)
                        : (isNear ? AppColors.warning.withOpacity(0.5) : AppColors.divider),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(catIcon, color: catColor, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                '${formatCurrency(spent)} of ${formatCurrency(b.monthlyLimit)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isExceeded ? AppColors.expense : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${percent.toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _getBudgetStatusColor(percent),
                              ),
                            ),
                            Text(
                              isExceeded
                                  ? 'Exceeded'
                                  : '${formatCompactCurrency(b.remaining(spent))} left',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isExceeded ? AppColors.expense : AppColors.income,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (val) {
                            if (val == 'edit') {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => SetBudgetDialog(
                                  initialBudget: b,
                                  preselectedCategory: b.category,
                                ),
                              );
                            } else if (val == 'delete') {
                              budgetProvider.deleteBudget(b.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppColors.expense)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getBudgetStatusColor(percent),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getBudgetStatusColor(double percent) {
    if (percent > 100) return AppColors.expense;
    if (percent >= 80) return AppColors.warning;
    return AppColors.income;
  }
}

