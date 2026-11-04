import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../services/database_service.dart';

/// Manages monthly budget state — overall and per-category limits.
class BudgetProvider extends ChangeNotifier {
  DatabaseService? _dbService;

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _budgetSubscription;

  // ── Getters ──────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// All configured budgets.
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);

  /// Returns the overall budget for [month]/[year], or `null` if none set.
  BudgetModel? getOverallBudget(int month, int year) {
    try {
      return _budgets.firstWhere(
        (b) => b.month == month && b.year == year && b.category == 'Overall',
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the budget for a specific [category] and [month]/[year], or `null`.
  BudgetModel? getCategoryBudget(String category, int month, int year) {
    try {
      return _budgets.firstWhere(
        (b) => b.month == month && b.year == year && b.category == category,
      );
    } catch (_) {
      return null;
    }
  }

  /// Whether the user has exceeded the budget for [category].
  bool isBudgetExceeded(String category, double spent, int month, int year) {
    final budget = getCategoryBudget(category, month, year);
    if (budget == null) return false;
    return budget.isOverBudget(spent);
  }

  /// Whether spending is at or above 80% of the category budget.
  bool isBudgetNearLimit(String category, double spent, int month, int year) {
    final budget = getCategoryBudget(category, month, year);
    if (budget == null) return false;
    return budget.isNearLimit(spent) && !budget.isOverBudget(spent);
  }

  // ── Initialisation ──────────────────────────────────────────────────
  void initialize(DatabaseService dbService) {
    _dbService = dbService;
    _isLoading = true;
    notifyListeners();

    _budgetSubscription?.cancel();
    _budgetSubscription = _dbService!.getBudgets().listen(
      (budgetList) {
        _budgets = budgetList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load budgets: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Set / update budget ─────────────────────────────────────────────
  Future<void> setBudget(BudgetModel budget) async {
    try {
      _setLoading(true);

      final index = _budgets.indexWhere(
        (b) =>
            b.category == budget.category &&
            b.month == budget.month &&
            b.year == budget.year,
      );

      if (_dbService != null) {
        if (index != -1) {
          final updated = budget.copyWith(id: _budgets[index].id);
          await _dbService!.setBudget(updated);
        } else {
          await _dbService!.setBudget(budget);
        }
      } else {
        if (index != -1) {
          _budgets[index] = budget;
        } else {
          _budgets.add(budget);
        }
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set budget: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      _setLoading(true);
      if (_dbService != null) {
        await _dbService!.deleteBudget(id);
      } else {
        _budgets.removeWhere((b) => b.id == id);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete budget: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void loadDemoData(List<BudgetModel> data) {
    _budgets = List.from(data);
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
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
