import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/bill_provider.dart';
import '../../providers/budget_provider.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'home/home_screen.dart';
import 'calendar/calendar_screen.dart';
import 'bills/bills_screen.dart';
import 'security/security_center_screen.dart';
import 'settings/settings_screen.dart';

/// The root shell container providing fixed 5-tab bottom navigation
/// for the FINTRACK Cybersecurity-Driven Finance Management application:
/// 1. HOME
/// 2. CALENDAR
/// 3. UPCOMING BILLS
/// 4. SECURITY CENTER
/// 5. SETTINGS
///
/// Ensures all 5 tabs maintain independent state via [IndexedStack]
/// and strictly respects the iPhone home indicator and safe areas.
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Home Dashboard
          HomeScreen(
            onNavigateTab: _onTabSelected,
          ),

          // Tab 1: Financial Calendar
          const CalendarScreen(),

          // Tab 2: Upcoming Bills Management
          const BillsScreen(),

          // Tab 3: Security Center Dashboard (Cybersecurity Monitoring & Threats)
          const SecurityCenterScreen(),

          // Tab 4: Settings & Profile
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: AppColors.card,
            indicatorColor: AppColors.softBlush,
            elevation: 0,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.roseAccent),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.roseAccent),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.roseAccent),
                label: 'Bills',
              ),
              NavigationDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield_rounded, color: AppColors.roseAccent),
                label: 'Security',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded, color: AppColors.roseAccent),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

