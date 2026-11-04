import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/security_provider.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/header_section.dart';
import '../../widgets/monthly_overview_card.dart';
import '../../widgets/expense_categories_section.dart';
import '../../widgets/recent_transactions_section.dart';
import '../../widgets/add_transaction_dialog.dart';

/// The central Home Dashboard screen of the FINTRACK application.
///
/// Contains:
/// A. Header Section (Greetings, User avatar, Notification alerts)
/// B. Monthly Financial Overview (Total Balance, Income, Expenses, Budget progress)
/// C. Expense Categories & Donut Breakdown
/// D. Recent Transactions & Search/Filter
/// E. Quick Budget & Financial Health Insight Card
class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        _initializeProviders();
        _isInitialized = true;
      }
    });
  }

  void _initializeProviders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    final dbService = auth.dbService ??
        DatabaseService(
          userId: auth.user?.uid ?? 'demo_user_001',
          isDemoMode: auth.isDemoMode,
        );

    txProvider.initialize(dbService);
    billProvider.initialize(dbService, txProvider);
    budgetProvider.initialize(dbService);
  }

  Future<void> _refreshData() async {
    _initializeProviders();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final secProvider = context.watch<SecurityProvider>();

    final income = txProvider.totalIncome;
    final expenses = txProvider.totalExpenses;
    final savings = income - expenses;
    final savingsRate = income > 0 ? ((savings / income) * 100).clamp(0.0, 100.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.roseAccent,
        backgroundColor: AppColors.card,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // A. Header Section
                SliverToBoxAdapter(
                  child: HeaderSection(
                    onAvatarTap: () => widget.onNavigateTab?.call(4), // Navigate to Settings
                    onNotificationTap: () => widget.onNavigateTab?.call(2), // Navigate to Bills
                    onSecurityTap: () => widget.onNavigateTab?.call(3), // Navigate to Security Center
                  ),
                ),

                // Cybersecurity Threat & Protection Banner
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onNavigateTab?.call(3), // Open Security Center
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: secProvider.pendingAlertsCount > 0
                                ? AppColors.warning.withOpacity(0.12)
                                : AppColors.pastelMint.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: secProvider.pendingAlertsCount > 0
                                  ? AppColors.warning.withOpacity(0.4)
                                  : AppColors.income.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                secProvider.pendingAlertsCount > 0
                                    ? Icons.gpp_maybe_rounded
                                    : Icons.verified_user_rounded,
                                color: secProvider.pendingAlertsCount > 0
                                    ? AppColors.warning
                                    : AppColors.income,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  secProvider.pendingAlertsCount > 0
                                      ? '${secProvider.pendingAlertsCount} Suspicious Activity Flagged • Tap to Inspect'
                                      : 'System Protected • Security Score: ${secProvider.securityScore}/100',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.textLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // B. Monthly Financial Overview Card
                const SliverToBoxAdapter(
                  child: MonthlyOverviewCard(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 18),
                ),

                // C. Expense Categories & Donut Chart
                const SliverToBoxAdapter(
                  child: ExpenseCategoriesSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 18),
                ),

                // D. Recent Transactions
                const SliverToBoxAdapter(
                  child: RecentTransactionsSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 18),
                ),

                // E. Quick Savings & Financial Health Summary Card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.softBlush,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.savings_rounded,
                                color: AppColors.roseAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Monthly Financial Health',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.pastelMint.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Net Savings',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        formatCurrency(savings),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: savings >= 0 ? AppColors.income : AppColors.expense,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.lightPeach.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Savings Rate',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${savingsRate.toStringAsFixed(1)}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding to ensure content is clear of bottom navigation bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 90),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const AddTransactionDialog(),
          );
        },
        backgroundColor: AppColors.roseAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

