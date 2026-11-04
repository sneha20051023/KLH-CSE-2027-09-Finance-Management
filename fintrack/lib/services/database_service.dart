import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/user_model.dart';
import 'demo_data_service.dart';

/// DatabaseService handles all data persistence for the FINTRACK app.
///
/// Operates in two modes:
/// - **Firebase mode**: Uses Cloud Firestore with path `users/{userId}/...`
/// - **Demo mode**: Uses in-memory Maps with sample data from [DemoDataService].
class DatabaseService {
  /// The authenticated user's ID.
  final String userId;

  /// Whether the service is running in demo/local mode.
  final bool isDemoMode;

  FirebaseFirestore? _firestore;

  // ---------------------------------------------------------------------------
  // In-memory storage for demo mode
  // ---------------------------------------------------------------------------
  final Map<String, TransactionModel> _demoTransactions = {};
  final Map<String, BillModel> _demoBills = {};
  final Map<String, BudgetModel> _demoBudgets = {};
  UserModel? _demoUserProfile;
  Map<String, dynamic> _demoSettings = {};

  // Stream controllers for demo mode (broadcast so multiple listeners work)
  final StreamController<List<TransactionModel>> _transactionController =
      StreamController<List<TransactionModel>>.broadcast();
  final StreamController<List<BillModel>> _billController =
      StreamController<List<BillModel>>.broadcast();
  final StreamController<List<BudgetModel>> _budgetController =
      StreamController<List<BudgetModel>>.broadcast();
  final StreamController<UserModel?> _userProfileController =
      StreamController<UserModel?>.broadcast();

  DatabaseService({required this.userId, this.isDemoMode = true}) {
    if (isDemoMode) {
      _loadDemoData();
    } else {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (_) {
        // Fallback to demo mode if Firestore cannot be reached
      }
    }
  }

  /// Pre-populates in-memory storage with sample data.
  void _loadDemoData() {
    final demoData = DemoDataService();

    for (final txn in demoData.getSampleTransactions()) {
      _demoTransactions[txn.id] = txn;
    }

    for (final bill in demoData.getSampleBills()) {
      _demoBills[bill.id] = bill;
    }

    for (final budget in demoData.getSampleBudgets()) {
      _demoBudgets[budget.id] = budget;
    }

    _demoUserProfile = demoData.getSampleUser();

    _demoSettings = {
      'currency': 'INR',
      'currencySymbol': '₹',
      'theme': 'light',
      'notifications': true,
      'billReminders': true,
      'reminderDaysBefore': 1,
    };
  }

  // ===========================================================================
  // FIRESTORE HELPERS
  // ===========================================================================

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    if (_firestore == null) return null;
    return _firestore!.collection('users').doc(userId);
  }

  CollectionReference<Map<String, dynamic>>? _subCollection(String name) {
    return _userDoc?.collection(name);
  }

  // ===========================================================================
  // TRANSACTION METHODS
  // ===========================================================================

  /// Adds a new transaction.
  Future<void> addTransaction(TransactionModel transaction) async {
    if (isDemoMode || _firestore == null) {
      _demoTransactions[transaction.id] = transaction;
      _emitTransactions();
      return;
    }

    try {
      await _subCollection('transactions')
          ?.doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  /// Updates an existing transaction.
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (isDemoMode || _firestore == null) {
      _demoTransactions[transaction.id] = transaction;
      _emitTransactions();
      return;
    }

    try {
      await _subCollection('transactions')
          ?.doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  /// Deletes a transaction by its ID.
  Future<void> deleteTransaction(String transactionId) async {
    if (isDemoMode || _firestore == null) {
      _demoTransactions.remove(transactionId);
      _emitTransactions();
      return;
    }

    try {
      await _subCollection('transactions')?.doc(transactionId).delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  /// Returns a real-time stream of all transactions, ordered by date descending.
  Stream<List<TransactionModel>> getTransactions() {
    if (isDemoMode || _firestore == null) {
      Future.microtask(() => _emitTransactions());
      return _transactionController.stream;
    }

    try {
      return _subCollection('transactions')!
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      return Stream.error('Failed to fetch transactions: $e');
    }
  }

  /// Returns transactions for a specific [month] and [year].
  Future<List<TransactionModel>> getTransactionsByMonth(
      int month, int year) async {
    if (isDemoMode || _firestore == null) {
      return _demoTransactions.values.where((txn) {
        return txn.date.month == month && txn.date.year == year;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final snapshot = await _subCollection('transactions')!
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions by month: $e');
    }
  }

  /// Returns transactions for a specific [date] (matching year, month, day).
  Future<List<TransactionModel>> getTransactionsByDate(DateTime date) async {
    if (isDemoMode || _firestore == null) {
      return _demoTransactions.values.where((txn) {
        return txn.date.year == date.year &&
            txn.date.month == date.month &&
            txn.date.day == date.day;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _subCollection('transactions')!
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions by date: $e');
    }
  }

  /// Returns transactions matching a specific [category].
  Future<List<TransactionModel>> getTransactionsByCategory(
      String category) async {
    if (isDemoMode || _firestore == null) {
      return _demoTransactions.values
          .where((txn) => txn.category.toLowerCase() == category.toLowerCase())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    try {
      final snapshot = await _subCollection('transactions')!
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions by category: $e');
    }
  }

  void _emitTransactions() {
    if (_transactionController.isClosed) return;
    final list = _demoTransactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _transactionController.add(list);
  }

  // ===========================================================================
  // BILL METHODS
  // ===========================================================================

  /// Adds a new bill.
  Future<void> addBill(BillModel bill) async {
    if (isDemoMode || _firestore == null) {
      _demoBills[bill.id] = bill;
      _emitBills();
      return;
    }

    try {
      await _subCollection('bills')?.doc(bill.id).set(bill.toMap());
    } catch (e) {
      throw Exception('Failed to add bill: $e');
    }
  }

  /// Updates an existing bill.
  Future<void> updateBill(BillModel bill) async {
    if (isDemoMode || _firestore == null) {
      _demoBills[bill.id] = bill;
      _emitBills();
      return;
    }

    try {
      await _subCollection('bills')?.doc(bill.id).update(bill.toMap());
    } catch (e) {
      throw Exception('Failed to update bill: $e');
    }
  }

  /// Deletes a bill by its ID.
  Future<void> deleteBill(String billId) async {
    if (isDemoMode || _firestore == null) {
      _demoBills.remove(billId);
      _emitBills();
      return;
    }

    try {
      await _subCollection('bills')?.doc(billId).delete();
    } catch (e) {
      throw Exception('Failed to delete bill: $e');
    }
  }

  /// Returns a real-time stream of all bills, ordered by due date ascending.
  Stream<List<BillModel>> getBills() {
    if (isDemoMode || _firestore == null) {
      Future.microtask(() => _emitBills());
      return _billController.stream;
    }

    try {
      return _subCollection('bills')!
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => BillModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      return Stream.error('Failed to fetch bills: $e');
    }
  }

  /// Returns bills whose due date is in the future or today.
  Future<List<BillModel>> getUpcomingBills() async {
    final now = DateTime.now();

    if (isDemoMode || _firestore == null) {
      return _demoBills.values
          .where((bill) =>
              bill.dueDate.isAfter(now) || _isSameDay(bill.dueDate, now))
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    try {
      final snapshot = await _subCollection('bills')!
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => BillModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming bills: $e');
    }
  }

  /// Returns bills whose due date has passed and are not marked as paid.
  Future<List<BillModel>> getOverdueBills() async {
    final now = DateTime.now();

    if (isDemoMode || _firestore == null) {
      return _demoBills.values
          .where((bill) =>
              bill.dueDate.isBefore(now) &&
              !_isSameDay(bill.dueDate, now) &&
              bill.status != BillStatus.paid)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    try {
      final snapshot = await _subCollection('bills')!
          .where('status', isNotEqualTo: BillStatus.paid.name)
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => BillModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch overdue bills: $e');
    }
  }

  void _emitBills() {
    if (_billController.isClosed) return;
    final list = _demoBills.values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _billController.add(list);
  }

  // ===========================================================================
  // BUDGET METHODS
  // ===========================================================================

  /// Sets (creates or updates) a budget.
  Future<void> setBudget(BudgetModel budget) async {
    if (isDemoMode || _firestore == null) {
      _demoBudgets[budget.id] = budget;
      _emitBudgets();
      return;
    }

    try {
      await _subCollection('budgets')?.doc(budget.id).set(budget.toMap());
    } catch (e) {
      throw Exception('Failed to set budget: $e');
    }
  }

  /// Deletes a budget by its ID.
  Future<void> deleteBudget(String budgetId) async {
    if (isDemoMode || _firestore == null) {
      _demoBudgets.remove(budgetId);
      _emitBudgets();
      return;
    }

    try {
      await _subCollection('budgets')?.doc(budgetId).delete();
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  /// Returns a real-time stream of all budgets.
  Stream<List<BudgetModel>> getBudgets() {
    if (isDemoMode || _firestore == null) {
      Future.microtask(() => _emitBudgets());
      return _budgetController.stream;
    }

    try {
      return _subCollection('budgets')!.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      return Stream.error('Failed to fetch budgets: $e');
    }
  }

  /// Returns the budget for a specific [category], [month], and [year].
  Future<BudgetModel?> getBudgetForCategory(
      String category, int month, int year) async {
    if (isDemoMode || _firestore == null) {
      return _demoBudgets.values.cast<BudgetModel?>().firstWhere(
            (budget) =>
                budget!.category.toLowerCase() == category.toLowerCase() &&
                budget.month == month &&
                budget.year == year,
            orElse: () => null,
          );
    }

    try {
      final snapshot = await _subCollection('budgets')!
          .where('category', isEqualTo: category)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return BudgetModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Failed to fetch budget for category: $e');
    }
  }

  void _emitBudgets() {
    if (_budgetController.isClosed) return;
    _budgetController.add(_demoBudgets.values.toList());
  }

  // ===========================================================================
  // USER PROFILE METHODS
  // ===========================================================================

  /// Creates a new user profile document.
  Future<void> createUserProfile(UserModel user) async {
    if (isDemoMode || _firestore == null) {
      _demoUserProfile = user;
      _userProfileController.add(user);
      return;
    }

    try {
      await _userDoc?.set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Updates specific fields of the user profile.
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (isDemoMode || _firestore == null) {
      if (_demoUserProfile != null) {
        final currentMap = _demoUserProfile!.toMap();
        currentMap.addAll(data);
        _demoUserProfile = UserModel.fromMap(currentMap);
        _userProfileController.add(_demoUserProfile);
      }
      return;
    }

    try {
      await _userDoc?.update(data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Fetches the user profile once.
  Future<UserModel?> getUserProfile() async {
    if (isDemoMode || _firestore == null) {
      return _demoUserProfile;
    }

    try {
      final doc = await _userDoc?.get();
      if (doc == null || !doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Returns a real-time stream of the user profile.
  Stream<UserModel?> getUserProfileStream() {
    if (isDemoMode || _firestore == null) {
      Future.microtask(() => _userProfileController.add(_demoUserProfile));
      return _userProfileController.stream;
    }

    try {
      return _userDoc!.snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromMap(doc.data()!);
      });
    } catch (e) {
      return Stream.error('Failed to stream user profile: $e');
    }
  }

  // ===========================================================================
  // SETTINGS METHODS
  // ===========================================================================

  /// Saves user settings.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    if (isDemoMode || _firestore == null) {
      _demoSettings.addAll(settings);
      return;
    }

    try {
      await _userDoc
          ?.collection('settings')
          .doc('preferences')
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  /// Retrieves user settings.
  Future<Map<String, dynamic>> getSettings() async {
    if (isDemoMode || _firestore == null) {
      return Map<String, dynamic>.from(_demoSettings);
    }

    try {
      final doc =
          await _userDoc?.collection('settings').doc('preferences').get();
      if (doc == null || !doc.exists) return {};
      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to fetch settings: $e');
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void dispose() {
    _transactionController.close();
    _billController.close();
    _budgetController.close();
    _userProfileController.close();
  }
}
