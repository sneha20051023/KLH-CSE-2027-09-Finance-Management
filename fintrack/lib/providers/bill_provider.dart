import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_model.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import 'transaction_provider.dart';

/// Manages recurring bill state — upcoming, overdue, paid.
///
/// When a bill is marked as paid, an expense transaction is automatically
/// created (via [TransactionProvider]) unless one is already linked.
class BillProvider extends ChangeNotifier {
  DatabaseService? _dbService;
  TransactionProvider? _transactionProvider;

  List<BillModel> _bills = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _billSubscription;

  // ── Getters ──────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// All bills.
  List<BillModel> get bills => List.unmodifiable(_bills);

  /// Bills that are not yet paid, sorted by due date (soonest first).
  List<BillModel> get upcomingBills {
    final list = _bills.where((b) => b.status != BillStatus.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Bills past their due date that have not been paid.
  List<BillModel> get overdueBills {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _bills
        .where((b) =>
            b.status != BillStatus.paid &&
            b.dueDate.isBefore(today))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Bills that have been marked as paid.
  List<BillModel> get paidBills {
    return _bills.where((b) => b.status == BillStatus.paid).toList();
  }

  /// Bills that are pending (not paid and not overdue).
  List<BillModel> get pendingBills {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _bills
        .where((b) =>
            b.status != BillStatus.paid &&
            !b.dueDate.isBefore(today))
        .toList();
  }

  /// Sum of amounts for all upcoming (unpaid) bills.
  double get totalUpcoming {
    return upcomingBills.fold(0.0, (sum, b) => sum + b.amount);
  }

  /// Returns bills whose due date matches a specific calendar date.
  List<BillModel> getBillsForDate(DateTime date) {
    return _bills
        .where((b) =>
            b.dueDate.year == date.year &&
            b.dueDate.month == date.month &&
            b.dueDate.day == date.day)
        .toList();
  }

  // ── Initialisation ──────────────────────────────────────────────────
  void initialize(
    DatabaseService dbService,
    TransactionProvider txProvider,
  ) {
    _dbService = dbService;
    _transactionProvider = txProvider;
    _isLoading = true;
    notifyListeners();

    _billSubscription?.cancel();
    _billSubscription = _dbService!.getBills().listen(
      (billList) {
        _bills = billList;
        _isLoading = false;
        _error = null;
        updateOverdueStatuses();
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load bills: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── CRUD operations ─────────────────────────────────────────────────
  Future<void> addBill(BillModel bill) async {
    try {
      _setLoading(true);
      if (_dbService != null) {
        await _dbService!.addBill(bill);
      } else {
        _bills.add(bill);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add bill: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBill(BillModel bill) async {
    try {
      _setLoading(true);
      if (_dbService != null) {
        await _dbService!.updateBill(bill);
      } else {
        final index = _bills.indexWhere((b) => b.id == bill.id);
        if (index != -1) {
          _bills[index] = bill;
        }
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update bill: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      _setLoading(true);
      if (_dbService != null) {
        await _dbService!.deleteBill(id);
      } else {
        _bills.removeWhere((b) => b.id == id);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete bill: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Marks a bill as paid.
  ///
  /// Crucially: creates an expense transaction ONLY if one is not already linked,
  /// preventing duplicate entries.
  Future<void> markBillAsPaid(String billId) async {
    try {
      final bill = _bills.firstWhere((b) => b.id == billId);

      // Prevent duplicate transaction creation
      String? linkedTxId = bill.linkedTransactionId;
      if (linkedTxId == null || linkedTxId.isEmpty) {
        linkedTxId = const Uuid().v4();

        final expenseTx = TransactionModel(
          id: linkedTxId,
          title: 'Bill: ${bill.name}',
          amount: bill.amount,
          type: TransactionType.expense,
          category: bill.category,
          date: DateTime.now(),
          paymentMethod: 'UPI',
          description: 'Payment for bill: ${bill.name}',
          createdAt: DateTime.now(),
        );

        if (_transactionProvider != null) {
          await _transactionProvider!.addTransaction(expenseTx);
        }
      }

      final updatedBill = bill.copyWith(
        status: BillStatus.paid,
        linkedTransactionId: linkedTxId,
      );

      await updateBill(updatedBill);
    } catch (e) {
      _error = 'Failed to mark bill as paid: $e';
      notifyListeners();
    }
  }

  /// Automatically updates bills whose due date has passed to [BillStatus.overdue].
  void updateOverdueStatuses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool changed = false;

    for (int i = 0; i < _bills.length; i++) {
      final b = _bills[i];
      if (b.status != BillStatus.paid &&
          b.dueDate.isBefore(today) &&
          b.status != BillStatus.overdue) {
        _bills[i] = b.copyWith(status: BillStatus.overdue);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void loadDemoData(List<BillModel> data) {
    _bills = List.from(data);
    updateOverdueStatuses();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _billSubscription?.cancel();
    super.dispose();
  }
}
