import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'add_bill_dialog.dart';

/// Section beneath the calendar dedicated to Bill Management and Reminders.
class UpcomingBillsSection extends StatelessWidget {
  const UpcomingBillsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final upcomingBills = billProvider.upcomingBills;
    final overdueBills = billProvider.overdueBills;
    final paidBills = billProvider.paidBills;

    final totalUnpaidAmount = billProvider.totalUpcoming;

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
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Bills',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Total Unpaid: ${formatCurrency(totalUnpaidAmount)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const AddBillDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. Overdue Bills Warning Banner (if any)
          if (overdueBills.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.expense.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.expense.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'OVERDUE BILLS (${overdueBills.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...overdueBills.map((b) => _buildBillTile(context, b, billProvider, isOverdue: true)),
                ],
              ),
            ),
          ],

          // 2. Upcoming Unpaid Bills
          if (upcomingBills.isEmpty && overdueBills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 44,
                      color: AppColors.income.withOpacity(0.7),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No Upcoming Bills',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'All your bills are paid or none have been scheduled.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              'Scheduled Payments',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            ...upcomingBills.map((b) => _buildBillTile(context, b, billProvider)),
          ],

          // 3. Paid Bills Accordion
          if (paidBills.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Paid Bills (${paidBills.length})',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.income,
                ),
              ),
              leading: const Icon(Icons.task_alt_rounded, color: AppColors.income, size: 20),
              childrenPadding: EdgeInsets.zero,
              children: paidBills.map((b) => _buildBillTile(context, b, billProvider, isPaid: true)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillTile(
    BuildContext context,
    BillModel bill,
    BillProvider billProvider, {
    bool isOverdue = false,
    bool isPaid = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppColors.expense.withOpacity(0.4)
              : (isPaid ? AppColors.income.withOpacity(0.3) : AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Category Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: getCategoryColor(bill.category).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              getCategoryIcon(bill.category),
              color: getCategoryColor(bill.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Bill Info
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Due ${formatDate(bill.dueDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isOverdue ? AppColors.expense : AppColors.textLight,
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    Text(
                      bill.recurrence.displayName,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            formatCurrency(bill.amount),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),

          // Action: Mark as Paid or Status
          if (!isPaid)
            ElevatedButton(
              onPressed: () {
                billProvider.markBillAsPaid(bill.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Marked "${bill.name}" as Paid! Expense transaction recorded.'),
                    backgroundColor: AppColors.income,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(50, 30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Paid',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.income,
                ),
              ),
            ),

          // More Options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'edit') {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => AddBillDialog(billToEdit: bill),
                );
              } else if (val == 'delete') {
                billProvider.deleteBill(bill.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.expense)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

