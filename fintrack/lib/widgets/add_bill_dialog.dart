import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Modal bottom sheet dialog for adding or editing a bill reminder.
class AddBillDialog extends StatefulWidget {
  final BillModel? billToEdit;

  const AddBillDialog({super.key, this.billToEdit});

  @override
  State<AddBillDialog> createState() => _AddBillDialogState();
}

class _AddBillDialogState extends State<AddBillDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descController;

  late String _selectedCategory;
  late DateTime _selectedDueDate;
  late BillRecurrence _selectedRecurrence;
  bool _isSaving = false;

  bool get _isEditMode => widget.billToEdit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.billToEdit;

    _nameController = TextEditingController(text: edit?.name ?? '');
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(2) : '',
    );
    _descController = TextEditingController(text: edit?.description ?? '');

    _selectedCategory = edit?.category ?? 'Bills & Utilities';
    _selectedDueDate = edit?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedRecurrence = edit?.recurrence ?? BillRecurrence.monthly;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
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
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final billProvider = Provider.of<BillProvider>(context, listen: false);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final BillStatus initialStatus = _selectedDueDate.isBefore(today)
        ? BillStatus.overdue
        : BillStatus.upcoming;

    final bill = BillModel(
      id: widget.billToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      amount: parsedAmount,
      category: _selectedCategory,
      dueDate: _selectedDueDate,
      recurrence: _selectedRecurrence,
      status: widget.billToEdit?.status ?? initialStatus,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      linkedTransactionId: widget.billToEdit?.linkedTransactionId,
      createdAt: widget.billToEdit?.createdAt ?? DateTime.now(),
    );

    if (_isEditMode) {
      await billProvider.updateBill(bill);
    } else {
      await billProvider.addBill(bill);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? 'Bill updated successfully!' : 'Bill created successfully!',
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Edit Bill' : 'Add New Bill',
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

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Bill Name',
                  hint: 'e.g., Electricity, Netflix, Wifi',
                  prefixIcon: Icons.receipt_outlined,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter bill name' : null,
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
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Enter a positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: AppConstants.expenseCategoryNames.contains(_selectedCategory)
                    ? _selectedCategory
                    : 'Bills & Utilities',
                decoration: _inputDecoration(
                  label: 'Category',
                  hint: 'Select Category',
                  prefixIcon: Icons.category_outlined,
                ),
                items: AppConstants.expenseCategoryNames.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: GoogleFonts.poppins(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),

              // Due Date Picker Field
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Date',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                          ),
                          Text(
                            formatDate(_selectedDueDate),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Recurrence Segmented / Dropdown
              Text(
                'Recurrence Frequency',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BillRecurrence.values.map((rec) {
                  final isSelected = _selectedRecurrence == rec;
                  return ChoiceChip(
                    label: Text(
                      rec.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.text,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                    ),
                    onSelected: (_) => setState(() => _selectedRecurrence = rec),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: _inputDecoration(
                  label: 'Notes / Account # (Optional)',
                  hint: 'Add payment reference or remarks',
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
                      ),
                      child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
                              _isEditMode ? 'Update Bill' : 'Save Bill',
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

