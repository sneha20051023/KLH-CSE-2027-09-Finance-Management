import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/security_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// The financial summary card on the FINTRACK dashboard.
///
/// Displays:
/// 1. Total Balance (Total Income - Total Expenses)
/// 2. Monthly Income
/// 3. Monthly Expenses
/// 4. Remaining Budget
/// 5. Percentage of monthly budget utilized
/// 6. Month selector (previous / next controls)
/// 7. Spending progress indicator
/// 8. Comparison with the previous month
class MonthlyOverviewCard extends StatelessWidget {
  const MonthlyOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final secProvider = context.watch<SecurityProvider>();
    final hideBalances = secProvider.hideBalances;

    final income = txProvider.totalIncome;
    final expenses = txProvider.totalExpenses;
    final balance = txProvider.totalBalance;

    final overallBudget = budgetProvider.getOverallBudget(
      txProvider.selectedMonth,
      txProvider.selectedYear,
    );

    final budgetLimit = overallBudget?.monthlyLimit ?? (income > 0 ? income : 50000.0);
    final remainingBudget = budgetLimit - expenses;
    final budgetUtilizedPercent = budgetLimit > 0
        ? ((expenses / budgetLimit) * 100).clamp(0.0, 999.0)
        : 0.0;

    // Previous month comparison
    final prevExpenses = txProvider.previousMonthExpenses;
    final expenseDiffPercent = percentageChange(expenses, prevExpenses);

    final monthName = getMonthName(txProvider.selectedMonth);
    final year = txProvider.selectedYear;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                  onPressed: () => txProvider.previousMonth(),
                  tooltip: 'Previous Month',
                ),
                GestureDetector(
                  onTap: () => _showMonthPicker(context, txProvider),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '$monthName $year',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  onPressed: () => txProvider.nextMonth(),
                  tooltip: 'Next Month',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Balance Label & Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TOTAL BALANCE',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => secProvider.togglePrivacyMode(!hideBalances),
                                child: Icon(
                                  hideBalances ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 16,
                                  color: AppColors.roseAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              hideBalances ? '₹ ••••••' : formatCurrency(balance),
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: balance >= 0 ? AppColors.text : AppColors.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (prevExpenses > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: expenseDiffPercent <= 0
                              ? AppColors.income.withOpacity(0.12)
                              : AppColors.expense.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              expenseDiffPercent <= 0
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                              size: 16,
                              color: expenseDiffPercent <= 0
                                  ? AppColors.income
                                  : AppColors.expense,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${expenseDiffPercent.abs().toStringAsFixed(1)}% vs last mo',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: expenseDiffPercent <= 0
                                    ? AppColors.income
                                    : AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Income, Expense, Remaining Cards Row
                Row(
                  children: [
                    // Income
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Income',
                        amount: income,
                        color: AppColors.income,
                        icon: Icons.arrow_downward_rounded,
                        bgColor: AppColors.income.withOpacity(0.08),
                        hideBalance: hideBalances,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expenses
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Expenses',
                        amount: expenses,
                        color: AppColors.expense,
                        icon: Icons.arrow_upward_rounded,
                        bgColor: AppColors.expense.withOpacity(0.08),
                        hideBalance: hideBalances,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Remaining Budget Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.savings_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remaining Budget',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              hideBalances ? '••••••' : formatCurrency(remainingBudget),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: remainingBudget >= 0
                                    ? AppColors.text
                                    : AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Limit: ${formatCompactCurrency(budgetLimit)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Spending progress bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Budget Utilized',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      '${budgetUtilizedPercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getProgressColor(budgetUtilizedPercent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (budgetUtilizedPercent / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(budgetUtilizedPercent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required Color bgColor,
    bool hideBalance = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              hideBalance ? '••••••' : formatCurrency(amount),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent > 100) return AppColors.expense;
    if (percent >= 80) return AppColors.warning;
    return AppColors.income;
  }

  void _showMonthPicker(BuildContext context, TransactionProvider txProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currentYear = txProvider.selectedYear;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Month ($currentYear)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final m = index + 1;
                  final isSelected = m == txProvider.selectedMonth;
                  return InkWell(
                    onTap: () {
                      txProvider.setMonth(m, currentYear);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        getMonthName(m).substring(0, 3),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

