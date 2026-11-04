import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/add_bill_dialog.dart';

/// Independent screen for Bill Management & Reminders.
///
/// Features:
/// - Summary cards for Total Due, Upcoming, Overdue, and Paid bills
/// - Segmented tabs: Upcoming, Paid, Overdue
/// - Bill cards with category icon, recurrence, due date countdown, and amount
/// - "Mark as Paid" action with one-click expense creation (without duplicates)
/// - Add, Edit, and Delete bill support
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMarkAsPaidDialog(BuildContext context, BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mark Bill as Paid',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark "${bill.name}" of ${formatCurrency(bill.amount)} as paid?',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pastelMint.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.income.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'An expense transaction will be recorded automatically so you do not have duplicate entries.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final billProvider = Provider.of<BillProvider>(context, listen: false);
              await billProvider.markBillAsPaid(bill.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Marked "${bill.name}" as paid & logged expense!'),
                    backgroundColor: AppColors.income,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.roseAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BillModel bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Bill', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${bill.name}"?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<BillProvider>(context, listen: false).deleteBill(bill.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bill deleted successfully.'),
                    backgroundColor: AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillTile(BillModel bill, {required bool isPaidList}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billDue = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    final daysDiff = billDue.difference(today).inDays;

    String dueText;
    Color badgeBg;
    Color badgeTextColor;

    if (bill.status == BillStatus.paid) {
      dueText = 'Paid ✓';
      badgeBg = AppColors.pastelMint;
      badgeTextColor = AppColors.income;
    } else if (daysDiff < 0) {
      dueText = 'Overdue by ${daysDiff.abs()}d';
      badgeBg = AppColors.softBlush;
      badgeTextColor = AppColors.expense;
    } else if (daysDiff == 0) {
      dueText = 'Due Today';
      badgeBg = AppColors.lightPeach;
      badgeTextColor = AppColors.warning;
    } else {
      dueText = 'Due in ${daysDiff}d';
      badgeBg = AppColors.softLavender;
      badgeTextColor = const Color(0xFF7A68A6);
    }

    final catColor = getCategoryColor(bill.category);
    final catIcon = getCategoryIcon(bill.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: daysDiff < 0 && bill.status != BillStatus.paid
              ? AppColors.expense.withOpacity(0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bill.category} • ${bill.recurrence.displayName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatCurrency(bill.amount),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dueText,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${formatDate(bill.dueDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (bill.status != BillStatus.paid)
                    ElevatedButton.icon(
                      onPressed: () => _showMarkAsPaidDialog(context, bill),
                      icon: const Icon(Icons.check_rounded, size: 15),
                      label: const Text('Mark Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.pastelMint.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.done_all_rounded, size: 14, color: AppColors.income),
                          const SizedBox(width: 4),
                          Text(
                            'Paid',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDelete(context, bill);
                      } else if (val == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => AddBillDialog(billToEdit: bill),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Bill'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.expense)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String subtext) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.softBlush,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 44,
                color: AppColors.roseAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtext,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final upcomingBills = billProvider.upcomingBills;
    final overdueBills = billProvider.overdueBills;
    final paidBills = billProvider.paidBills;

    final totalUnpaidAmount = billProvider.totalUpcoming;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Upcoming Bills',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // Top Metric Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.softBlush, Color(0xFFFFECEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.roseAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL DUE THIS MONTH',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatCurrency(totalUnpaidAmount),
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.roseAccent.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm_rounded, size: 16, color: AppColors.roseAccent),
                              const SizedBox(width: 4),
                              Text(
                                '${upcomingBills.length} pending',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.roseAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mini metric row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.roseAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${upcomingBills.length} Upcoming',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.expense),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${overdueBills.length} Overdue',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: overdueBills.isNotEmpty ? AppColors.expense : AppColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.income),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${paidBills.length} Paid',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.income,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

              // Segmented Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.roseAccent,
                  indicatorWeight: 3,
                  labelColor: AppColors.roseAccent,
                  unselectedLabelColor: AppColors.textLight,
                  labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: 'Upcoming (${upcomingBills.length})'),
                    Tab(text: 'Paid (${paidBills.length})'),
                    Tab(text: 'Overdue (${overdueBills.length})'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Upcoming List
                    upcomingBills.isEmpty
                        ? _buildEmptyState('No upcoming bills!', "You're all caught up with your upcoming payments ✨")
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 90),
                            physics: const BouncingScrollPhysics(),
                            itemCount: upcomingBills.length,
                            itemBuilder: (ctx, index) => _buildBillTile(upcomingBills[index], isPaidList: false),
                          ),

                    // Paid List
                    paidBills.isEmpty
                        ? _buildEmptyState('No paid bills yet', 'Bills you mark as paid will be recorded here.')
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 90),
                            physics: const BouncingScrollPhysics(),
                            itemCount: paidBills.length,
                            itemBuilder: (ctx, index) => _buildBillTile(paidBills[index], isPaidList: true),
                          ),

                    // Overdue List
                    overdueBills.isEmpty
                        ? _buildEmptyState('No overdue bills!', 'Great job! You have zero overdue bills 🎉')
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 90),
                            physics: const BouncingScrollPhysics(),
                            itemCount: overdueBills.length,
                            itemBuilder: (ctx, index) => _buildBillTile(overdueBills[index], isPaidList: false),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const AddBillDialog(),
          );
        },
        backgroundColor: AppColors.roseAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Add Bill',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
