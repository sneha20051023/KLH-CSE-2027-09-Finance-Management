import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/security_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// The top header section of the FINTRACK dashboard.
///
/// Displays:
/// - Brand logo and app name
/// - Personalized dynamic greeting (Good Morning / Afternoon / Evening, [Name])
/// - Notification icon with badge for pending/overdue bills
/// - Cybersecurity Shield with Threat Badge & Security Score
/// - Clickable avatar that routes to the Profile & Settings screen
/// - Selected month and year
class HeaderSection extends StatelessWidget {
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSecurityTap;

  const HeaderSection({
    super.key,
    this.onAvatarTap,
    this.onNotificationTap,
    this.onSecurityTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final billProvider = context.watch<BillProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final secProvider = context.watch<SecurityProvider>();

    final userName = auth.user?.fullName.split(' ').first ?? 'Harini';
    final upcomingCount = billProvider.upcomingBills.length;
    final overdueCount = billProvider.overdueBills.length;
    final totalAlerts = upcomingCount + overdueCount;
    final threatCount = secProvider.pendingAlertsCount;
    final secScore = secProvider.securityScore;

    final monthName = getMonthName(txProvider.selectedMonth);
    final year = txProvider.selectedYear;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Logo + Brand & Actions
          Row(
            children: [
              // Logo icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Title and subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'FIN',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'TRACK',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$monthName $year',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Cybersecurity Shield Status Icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      if (onSecurityTap != null) {
                        onSecurityTap!();
                      } else {
                        Navigator.pushNamed(context, '/security');
                      }
                    },
                    icon: Icon(
                      threatCount > 0 ? Icons.shield_rounded : Icons.shield_outlined,
                      color: threatCount > 0 ? AppColors.warning : AppColors.text,
                      size: 24,
                    ),
                    tooltip: 'Security Center ($secScore/100)',
                  ),
                  if (threatCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$threatCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              // Notification bell with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      if (onNotificationTap != null) {
                        onNotificationTap!();
                      } else {
                        _showNotificationDialog(context, billProvider);
                      }
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.text,
                      size: 26,
                    ),
                    tooltip: 'Bill Notifications',
                  ),
                  if (totalAlerts > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: overdueCount > 0 ? AppColors.expense : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$totalAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              // Profile Avatar
              GestureDetector(
                onTap: () {
                  if (onAvatarTap != null) {
                    onAvatarTap!();
                  } else {
                    Navigator.pushNamed(context, '/profile');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.softBlush,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'H',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.roseAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Greeting row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hello, $userName!',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Let's make your money work better.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (auth.isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softBlush,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.roseAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Demo Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, BillProvider billProvider) {
    final upcoming = billProvider.upcomingBills;
    final overdue = billProvider.overdueBills;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Bill Reminders',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (upcoming.isEmpty && overdue.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: AppColors.income.withOpacity(0.6)),
                        const SizedBox(height: 12),
                        Text(
                          'All caught up!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'No pending or overdue bills at this time.',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (overdue.isNotEmpty) ...[
                        Text(
                          '⚠️ OVERDUE BILLS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.expense,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...overdue.map((b) => _buildNotificationTile(context, b, billProvider, isOverdue: true)),
                        const SizedBox(height: 16),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        Text(
                          'UPCOMING BILLS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...upcoming.map((b) => _buildNotificationTile(context, b, billProvider, isOverdue: false)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(BuildContext context, dynamic bill, BillProvider billProvider, {required bool isOverdue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOverdue ? AppColors.expense.withOpacity(0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue ? AppColors.expense.withOpacity(0.3) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_rounded : Icons.calendar_today_rounded,
            color: isOverdue ? AppColors.expense : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Due: ${formatDate(bill.dueDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isOverdue ? AppColors.expense : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(bill.amount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              billProvider.markBillAsPaid(bill.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: AppColors.income.withOpacity(0.12),
              foregroundColor: AppColors.income,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

