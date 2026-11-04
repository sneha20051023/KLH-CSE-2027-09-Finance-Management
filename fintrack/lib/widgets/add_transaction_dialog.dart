import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/security_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Bottom sheet dialog for creating or updating a transaction.
class AddTransactionDialog extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  final DateTime? initialDate;

  const AddTransactionDialog({
    super.key,
    this.transactionToEdit,
    this.initialDate,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late TransactionType _selectedType;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isSaving = false;

  bool get _isEditMode => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;

    _titleController = TextEditingController(text: edit?.title ?? '');
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: edit?.description ?? '');

    _selectedType = edit?.type ?? TransactionType.expense;
    _selectedDate = edit?.date ?? widget.initialDate ?? DateTime.now();
    _selectedPaymentMethod = edit?.paymentMethod ?? 'UPI';

    if (edit != null) {
      _selectedCategory = edit.category;
    } else {
      _selectedCategory = _selectedType == TransactionType.income
          ? AppConstants.incomeCategoryNames.first
          : AppConstants.expenseCategoryNames.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      if (type == TransactionType.income) {
        _selectedCategory = AppConstants.incomeCategoryNames.first;
      } else {
        _selectedCategory = AppConstants.expenseCategoryNames.first;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    final transaction = TransactionModel(
      id: widget.transactionToEdit?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: parsedAmount,
      type: _selectedType,
      category: _selectedCategory,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      description: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.transactionToEdit?.createdAt ?? DateTime.now(),
    );

    final secProvider = Provider.of<SecurityProvider>(context, listen: false);

    if (_isEditMode) {
      await txProvider.updateTransaction(transaction);
    } else {
      await txProvider.addTransaction(transaction);
      // Real-time cybersecurity anomaly inspection
      secProvider.inspectTransaction(
        transaction: transaction,
        history: txProvider.transactions,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);

      final wasFlagged = secProvider.fraudAlerts.isNotEmpty &&
          secProvider.fraudAlerts.first.transactionId == transaction.id;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFlagged
                ? '⚠️ Anomaly Flagged: ${secProvider.fraudAlerts.first.reasons.first}'
                : (_isEditMode ? 'Transaction updated successfully!' : 'Transaction added successfully!'),
          ),
          backgroundColor: wasFlagged ? AppColors.warning : AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = _selectedType == TransactionType.income
        ? AppConstants.incomeCategoryNames
        : AppConstants.expenseCategoryNames;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Edit Transaction' : 'Add Transaction',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Income / Expense Segmented Buttons
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Expense',
                        icon: Icons.arrow_upward_rounded,
                        isSelected: _selectedType == TransactionType.expense,
                        color: AppColors.expense,
                        onTap: () => _onTypeChanged(TransactionType.expense),
                      ),
                    ),
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Income',
                        icon: Icons.arrow_downward_rounded,
                        isSelected: _selectedType == TransactionType.income,
                        color: AppColors.income,
                        onTap: () => _onTypeChanged(TransactionType.income),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  label: 'Title',
                  hint: 'e.g., Grocery Shopping, Salary',
                  prefixIcon: Icons.title_rounded,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter a title' : null,
              ),

              const SizedBox(height: 14),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: 'Amount (₹)',
                  hint: '0.00',
                  prefixIcon: Icons.currency_rupee_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter an amount';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Enter a positive number';
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: categoryOptions.contains(_selectedCategory)
                    ? _selectedCategory
                    : categoryOptions.first,
                decoration: _inputDecoration(
                  label: 'Category',
                  hint: 'Select Category',
                  prefixIcon: Icons.category_outlined,
                ),
                items: categoryOptions.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(getCategoryIcon(cat), size: 18, color: getCategoryColor(cat)),
                        const SizedBox(width: 8),
                        Text(cat, style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: 14),

              // Date Picker & Payment Method Row
              Row(
                children: [
                  // Date Picker Field
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                formatDate(_selectedDate),
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Payment Method Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: _inputDecoration(
                        label: 'Payment',
                        hint: 'Method',
                        prefixIcon: Icons.payment_outlined,
                      ),
                      items: AppConstants.paymentMethods.map((pm) {
                        return DropdownMenuItem(
                          value: pm,
                          child: Text(pm, style: GoogleFonts.poppins(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPaymentMethod = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Notes / Description Field
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: _inputDecoration(
                  label: 'Notes (Optional)',
                  hint: 'Add any extra notes...',
                  prefixIcon: Icons.notes_rounded,
                ),
              ),

              const SizedBox(height: 22),

              // Save & Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: AppColors.textLight, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isEditMode ? 'Update' : 'Save Transaction',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

