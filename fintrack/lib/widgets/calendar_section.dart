import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/transaction_model.dart';
import '../models/bill_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/bill_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'add_transaction_dialog.dart';
import 'transaction_list_tile.dart';

/// Interactive monthly calendar that displays transactions and bills for each day.
class CalendarSection extends StatefulWidget {
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final billProvider = context.watch<BillProvider>();

    final allTx = txProvider.allTransactions;
    final allBills = billProvider.bills;

    final selectedDate = _selectedDay ?? _focusedDay;
    final dayTx = txProvider.getTransactionsForDate(selectedDate);
    final dayBills = billProvider.getBillsForDate(selectedDate);

    final double dayIncome = dayTx
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final double dayExpense = dayTx
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

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
          // Section Title
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
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Financial Calendar',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.today_rounded, color: AppColors.primary),
                tooltip: 'Go to Today',
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Legend for markers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.income, 'Income'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.expense, 'Expense'),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.blue, 'Bills'),
            ],
          ),

          const SizedBox(height: 12),

          // TableCalendar Widget
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
              rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: GoogleFonts.poppins(color: AppColors.text),
              weekendTextStyle: GoogleFonts.poppins(color: AppColors.textLight),
              todayDecoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              todayTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            selectedDayPredicate: (day) => _isSameDay(_selectedDay ?? _focusedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              txProvider.setMonth(focusedDay.month, focusedDay.year);
            },
            // Custom cell markers builder
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final hasIncome = allTx.any(
                  (t) => _isSameDay(t.date, date) && t.type == TransactionType.income,
                );
                final hasExpense = allTx.any(
                  (t) => _isSameDay(t.date, date) && t.type == TransactionType.expense,
                );
                final hasBill = allBills.any(
                  (b) => _isSameDay(b.dueDate, date),
                );

                if (!hasIncome && !hasExpense && !hasBill) return const SizedBox();

                return Positioned(
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasIncome)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.income,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasExpense)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.expense,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasBill)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),

          // Selected Day Detailed Breakdown Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Daily Financial Activity',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => AddTransactionDialog(initialDate: selectedDate),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add on Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Day Totals
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day Income',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                      ),
                      Text(
                        formatCurrency(dayIncome),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day Expense',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                      ),
                      Text(
                        formatCurrency(dayExpense),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Day Bills (if any)
          if (dayBills.isNotEmpty) ...[
            Text(
              'Bills Due on this date:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            ...dayBills.map((b) => _buildDayBillTile(context, b, billProvider)),
            const SizedBox(height: 12),
          ],

          // Day Transactions (if any)
          if (dayTx.isNotEmpty) ...[
            Text(
              'Transactions on this date:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            ...dayTx.map((tx) => TransactionListTile(transaction: tx)),
          ] else if (dayBills.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No transactions or bills recorded for this date.',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildDayBillTile(BuildContext context, BillModel bill, BillProvider billProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bill.status.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bill.status.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_outlined, color: bill.status.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bill.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          Text(
            formatCurrency(bill.amount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bill.status.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bill.status.displayName,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: bill.status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

