import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../widgets/header_section.dart';
import '../../widgets/monthly_overview_card.dart';
import '../../widgets/expense_categories_section.dart';
import '../../widgets/recent_transactions_section.dart';
import '../../widgets/calendar_section.dart';
import '../../widgets/upcoming_bills_section.dart';
import '../../widgets/budget_section.dart';
import '../../widgets/analytics_section.dart';
import '../../widgets/add_transaction_dialog.dart';

/// The central single-page dashboard of the FINTRACK application.
///
/// Combines all modules into an intuitive, seamless scrollable view:
/// A. Header Section
/// B. Monthly Financial Overview
/// C. Expense Categories & Donut Breakdown
/// D. Daily Transactions & Filtering
/// E. Financial Calendar & Day Activity
/// F. Bill Management & Due Date Reminders
/// G. Monthly Budget Management & Alerts
/// H. Financial Analytics & Trends
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeProviders();
      _isInitialized = true;
    }
  }

  void _initializeProviders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // Get or create DatabaseService for the logged-in / demo user
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // A. Header Section
                const SliverToBoxAdapter(
                  child: HeaderSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // B. Monthly Financial Overview
                const SliverToBoxAdapter(
                  child: MonthlyOverviewCard(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // C. Expense Categories
                const SliverToBoxAdapter(
                  child: ExpenseCategoriesSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // D. Daily Transactions
                const SliverToBoxAdapter(
                  child: RecentTransactionsSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // E. Calendar Section
                const SliverToBoxAdapter(
                  child: CalendarSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // F. Upcoming Bills Section
                const SliverToBoxAdapter(
                  child: UpcomingBillsSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // G. Budget Management Section
                const SliverToBoxAdapter(
                  child: BudgetSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // H. Financial Analytics Section
                const SliverToBoxAdapter(
                  child: AnalyticsSection(),
                ),

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const AddTransactionDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Transaction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

