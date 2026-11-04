import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

/// Manages transaction state — listing, filtering, sorting, and CRUD.
class TransactionProvider extends ChangeNotifier {
  DatabaseService? _dbService;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // ── Filters & sort ───────────────────────────────────────────────────
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterType = 'All'; // All, Income, Expense
  String _sortBy = 'date'; // date, amount
  bool _sortAscending = false;

  StreamSubscription? _transactionSubscription;

  // ── Getters ──────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  String get searchQuery => _searchQuery;
  String get filterCategory => _filterCategory;
  String get filterType => _filterType;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  /// Returns the raw, unfiltered transaction list.
  List<TransactionModel> get allTransactions =>
      List.unmodifiable(_transactions);

  /// Returns transactions filtered by selected month/year, search query,
  /// category, type, and then sorted by the chosen criteria.
  List<TransactionModel> get transactions {
    List<TransactionModel> filtered = _transactions.where((t) {
      // 1. Filter by selected month & year
      if (t.date.month != _selectedMonth || t.date.year != _selectedYear) {
        return false;
      }

      // 2. Filter by search query (case-insensitive title match)
      if (_searchQuery.isNotEmpty &&
          !t.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !(t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)) {
        return false;
      }

      // 3. Filter by category
      if (_filterCategory != 'All' && t.category != _filterCategory) {
        return false;
      }

      // 4. Filter by type (Income / Expense)
      if (_filterType != 'All') {
        final expectedType = _filterType == 'Income'
            ? TransactionType.income
            : TransactionType.expense;
        if (t.type != expectedType) {
          return false;
        }
      }

      return true;
    }).toList();

    // 5. Sort
    filtered.sort((a, b) {
      int comparison;
      if (_sortBy == 'amount') {
        comparison = a.amount.compareTo(b.amount);
      } else {
        // Default: sort by date
        comparison = a.date.compareTo(b.date);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  /// Total income for the selected month/year.
  double get totalIncome {
    return _transactionsForSelectedMonth
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total expenses for the selected month/year.
  double get totalExpenses {
    return _transactionsForSelectedMonth
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Net balance for the selected month/year.
  double get totalBalance => totalIncome - totalExpenses;

  /// Alias for [totalBalance].
  double get monthlyBalance => totalBalance;

  /// Map of category name → total spent for the selected month/year.
  /// Only expense transactions are considered.
  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    for (final t in _transactionsForSelectedMonth) {
      if (t.type == TransactionType.expense) {
        totals[t.category] = (totals[t.category] ?? 0.0) + t.amount;
      }
    }
    return totals;
  }

  /// Previous month's total expenses (for trend comparison).
  double get previousMonthExpenses {
    final prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    final prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.month == prevMonth &&
            t.date.year == prevYear)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Previous month's total income (for trend comparison).
  double get previousMonthIncome {
    final prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    final prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.month == prevMonth &&
            t.date.year == prevYear)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Returns all transactions that fall on a specific calendar date.
  List<TransactionModel> getTransactionsForDate(DateTime date) {
    return _transactions
        .where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .toList();
  }

  /// Unfiltered transactions for the selected month/year.
  List<TransactionModel> get _transactionsForSelectedMonth {
    return _transactions
        .where((t) =>
            t.date.month == _selectedMonth && t.date.year == _selectedYear)
        .toList();
  }

  // ── Initialisation ──────────────────────────────────────────────────
  void initialize(DatabaseService dbService) {
    _dbService = dbService;
    _isLoading = true;
    notifyListeners();

    _transactionSubscription?.cancel();
    _transactionSubscription = _dbService!.getTransactions().listen(
      (txList) {
        _transactions = txList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load transactions: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Month navigation ────────────────────────────────────────────────
  void setMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    notifyListeners();
  }

  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    notifyListeners();
  }

  // ── CRUD operations ─────────────────────────────────────────────────
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      _setLoading(true);
      if (_dbService != null) {
        await _dbService!.addTransaction(transaction);
      } else {
        _transactions.insert(0, transaction);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      _setLoading(true);
      if (_dbService != null) {
        await _dbService!.updateTransaction(transaction);
      } else {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = transaction;
        }
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update transaction: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      _setLoading(true);
      if (_dbService != null) {
        await _dbService!.deleteTransaction(id);
      } else {
        _transactions.removeWhere((t) => t.id == id);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete transaction: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── Filter / sort setters ───────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  void setSortBy(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    notifyListeners();
  }

  void loadDemoData(List<TransactionModel> data) {
    _transactions = List.from(data);
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
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
