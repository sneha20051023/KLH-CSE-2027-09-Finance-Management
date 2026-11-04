import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import 'transaction_list_tile.dart';
import 'add_transaction_dialog.dart';

/// The Recent Transactions Section on the FINTRACK dashboard.
///
/// Features:
/// - Real-time search by title or description
/// - Type filters (All, Income, Expense)
/// - Category horizontal scrollable chips
/// - Sort by Date or Amount (asc/desc)
/// - "View All" toggle
/// - Edit and Delete transaction actions
class RecentTransactionsSection extends StatefulWidget {
  const RecentTransactionsSection({super.key});

  @override
  State<RecentTransactionsSection> createState() =>
      _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState extends State<RecentTransactionsSection> {
  final TextEditingController _searchController = TextEditingController();
  bool _showAll = false;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;
    final totalCount = transactions.length;

    final displayedTransactions =
        _showAll ? transactions : transactions.take(5).toList();

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
          // Section Header
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
                        Icons.receipt_long_rounded,
                        color: AppColors.roseAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Recent Transactions',
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
              Row(
                children: [
                  // Search toggle icon
                  IconButton(
                    icon: Icon(
                      _showSearch ? Icons.close_rounded : Icons.search_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchController.clear();
                          txProvider.setSearchQuery('');
                        }
                      });
                    },
                    tooltip: 'Search',
                  ),
                  // Add Transaction shortcut
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const AddTransactionDialog(),
                      );
                    },
                    tooltip: 'Add Transaction',
                  ),
                ],
              ),
            ],
          ),

          // Search Field (collapsible)
          if (_showSearch) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => txProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search by title or note...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          txProvider.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Filter & Sort Controls Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Type filters
                _buildTypeChip('All', txProvider),
                const SizedBox(width: 6),
                _buildTypeChip('Income', txProvider),
                const SizedBox(width: 6),
                _buildTypeChip('Expense', txProvider),
                const SizedBox(width: 12),

                // Sort toggle: Date / Amount
                ActionChip(
                  avatar: Icon(
                    txProvider.sortBy == 'date'
                        ? Icons.calendar_today_rounded
                        : Icons.attach_money_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Sort: ${txProvider.sortBy.toUpperCase()} ${txProvider.sortAscending ? '▲' : '▼'}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  backgroundColor: AppColors.accent,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: () {
                    if (txProvider.sortBy == 'date') {
                      txProvider.setSortBy('amount', false);
                    } else if (txProvider.sortBy == 'amount' && !txProvider.sortAscending) {
                      txProvider.setSortBy('amount', true);
                    } else {
                      txProvider.setSortBy('date', false);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transactions List or Empty State
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 48,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions found',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try adjusting your search or add a new transaction',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const AddTransactionDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedTransactions.length,
              itemBuilder: (context, index) {
                final tx = displayedTransactions[index];
                return TransactionListTile(
                  transaction: tx,
                  onDelete: () => _confirmDelete(context, txProvider, tx),
                );
              },
            ),

            // View All / View Less Toggle
            if (totalCount > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  icon: Icon(
                    _showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _showAll
                        ? 'Show Less'
                        : 'View All ($totalCount transactions)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, TransactionProvider txProvider) {
    final isSelected = txProvider.filterType == type;

    return FilterChip(
      label: Text(
        type,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.text,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
      ),
      onSelected: (_) => txProvider.setFilterType(type),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionProvider txProvider,
    TransactionModel tx,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Transaction?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${tx.title}"?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              txProvider.deleteTransaction(tx.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

