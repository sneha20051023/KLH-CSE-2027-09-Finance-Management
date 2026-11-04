import '../models/transaction_model.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/user_model.dart';

/// DemoDataService provides realistic sample data for the FINTRACK app
/// when running in demo/local mode (without Firebase).
///
/// All dates are computed relative to [DateTime.now()] so the data
/// always appears current regardless of when the app is launched.
class DemoDataService {
  /// Returns sample transactions spread across the current month.
  List<TransactionModel> getSampleTransactions() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    return [
      // ── Income ──────────────────────────────────────────────────────────
      TransactionModel(
        id: 'txn_demo_001',
        title: 'Salary',
        amount: 60000.0,
        category: 'Salary',
        type: TransactionType.income,
        date: DateTime(year, month, 1, 9, 0),
        paymentMethod: 'Net Banking',
        description: 'Monthly salary credit',
        createdAt: DateTime(year, month, 1),
      ),
      TransactionModel(
        id: 'txn_demo_002',
        title: 'Freelance Project',
        amount: 15000.0,
        category: 'Freelance',
        type: TransactionType.income,
        date: DateTime(year, month, 15, 14, 30),
        paymentMethod: 'UPI',
        description: 'UI design project payment',
        createdAt: DateTime(year, month, 15),
      ),

      // ── Expenses ────────────────────────────────────────────────────────
      TransactionModel(
        id: 'txn_demo_003',
        title: 'Grocery Shopping',
        amount: 2500.0,
        category: 'Groceries',
        type: TransactionType.expense,
        date: DateTime(year, month, 3, 11, 15),
        paymentMethod: 'UPI',
        description: 'Weekly groceries from BigBasket',
        createdAt: DateTime(year, month, 3),
      ),
      TransactionModel(
        id: 'txn_demo_004',
        title: 'Restaurant Dinner',
        amount: 1500.0,
        category: 'Food & Dining',
        type: TransactionType.expense,
        date: DateTime(year, month, 5, 20, 0),
        paymentMethod: 'Credit Card',
        description: 'Dinner with friends at Barbeque Nation',
        createdAt: DateTime(year, month, 5),
      ),
      TransactionModel(
        id: 'txn_demo_005',
        title: 'Uber Rides',
        amount: 800.0,
        category: 'Transportation',
        type: TransactionType.expense,
        date: DateTime(year, month, 6, 8, 45),
        paymentMethod: 'UPI',
        description: 'Cab to office and back',
        createdAt: DateTime(year, month, 6),
      ),
      TransactionModel(
        id: 'txn_demo_006',
        title: 'Amazon Shopping',
        amount: 3000.0,
        category: 'Shopping',
        type: TransactionType.expense,
        date: DateTime(year, month, 7, 16, 30),
        paymentMethod: 'Credit Card',
        description: 'Headphones and accessories',
        createdAt: DateTime(year, month, 7),
      ),
      TransactionModel(
        id: 'txn_demo_007',
        title: 'House Rent',
        amount: 15000.0,
        category: 'Housing & Rent',
        type: TransactionType.expense,
        date: DateTime(year, month, 1, 10, 0),
        paymentMethod: 'Net Banking',
        description: 'Monthly house rent',
        createdAt: DateTime(year, month, 1),
      ),
      TransactionModel(
        id: 'txn_demo_008',
        title: 'Electricity Bill',
        amount: 1200.0,
        category: 'Bills & Utilities',
        type: TransactionType.expense,
        date: DateTime(year, month, 5, 12, 0),
        paymentMethod: 'UPI',
        description: 'Monthly electricity bill',
        createdAt: DateTime(year, month, 5),
      ),
      TransactionModel(
        id: 'txn_demo_009',
        title: 'Internet Bill',
        amount: 799.0,
        category: 'Bills & Utilities',
        type: TransactionType.expense,
        date: DateTime(year, month, 8, 10, 30),
        paymentMethod: 'UPI',
        description: 'High-speed fiber bill',
        createdAt: DateTime(year, month, 8),
      ),
      TransactionModel(
        id: 'txn_demo_010',
        title: 'Gym Membership',
        amount: 1500.0,
        category: 'Health & Fitness',
        type: TransactionType.expense,
        date: DateTime(year, month, 10, 7, 0),
        paymentMethod: 'UPI',
        description: 'Monthly fitness pass',
        createdAt: DateTime(year, month, 10),
      ),
      TransactionModel(
        id: 'txn_demo_011',
        title: 'Online Course',
        amount: 2999.0,
        category: 'Education',
        type: TransactionType.expense,
        date: DateTime(year, month, 12, 18, 0),
        paymentMethod: 'Credit Card',
        description: 'Full stack development bootcamp',
        createdAt: DateTime(year, month, 12),
      ),
      TransactionModel(
        id: 'txn_demo_012',
        title: 'Movie Tickets',
        amount: 600.0,
        category: 'Entertainment',
        type: TransactionType.expense,
        date: DateTime(year, month, 14, 19, 30),
        paymentMethod: 'UPI',
        description: 'IMAX movie night',
        createdAt: DateTime(year, month, 14),
      ),
      TransactionModel(
        id: 'txn_demo_013',
        title: 'Weekend Getaway',
        amount: 4500.0,
        category: 'Travel',
        type: TransactionType.expense,
        date: DateTime(year, month, 18, 9, 0),
        paymentMethod: 'Debit Card',
        description: 'Resort stay & fuel',
        createdAt: DateTime(year, month, 18),
      ),
      TransactionModel(
        id: 'txn_demo_014',
        title: 'Netflix Subscription',
        amount: 199.0,
        category: 'Subscriptions',
        type: TransactionType.expense,
        date: DateTime(year, month, 15, 0, 0),
        paymentMethod: 'Credit Card',
        description: 'Monthly Netflix standard',
        createdAt: DateTime(year, month, 15),
      ),
      TransactionModel(
        id: 'txn_demo_015',
        title: 'Spotify Subscription',
        amount: 119.0,
        category: 'Subscriptions',
        type: TransactionType.expense,
        date: DateTime(year, month, 16, 0, 0),
        paymentMethod: 'UPI',
        description: 'Monthly Spotify premium',
        createdAt: DateTime(year, month, 16),
      ),
      TransactionModel(
        id: 'txn_demo_016',
        title: 'Miscellaneous',
        amount: 500.0,
        category: 'Others',
        type: TransactionType.expense,
        date: DateTime(year, month, 20, 15, 0),
        paymentMethod: 'Cash',
        description: 'Small daily items',
        createdAt: DateTime(year, month, 20),
      ),
    ];
  }

  /// Returns sample recurring and upcoming bills.
  List<BillModel> getSampleBills() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    return [
      BillModel(
        id: 'bill_demo_001',
        name: 'House Rent',
        amount: 15000.0,
        category: 'Housing & Rent',
        dueDate: DateTime(year, month, 1),
        recurrence: BillRecurrence.monthly,
        status: BillStatus.paid,
        linkedTransactionId: 'txn_demo_007',
        description: 'Monthly house rent',
        createdAt: DateTime(year, month, 1),
      ),
      BillModel(
        id: 'bill_demo_002',
        name: 'Electricity Bill',
        amount: 1200.0,
        category: 'Bills & Utilities',
        dueDate: DateTime(year, month, 5),
        recurrence: BillRecurrence.monthly,
        status: BillStatus.paid,
        linkedTransactionId: 'txn_demo_008',
        description: 'State electricity board',
        createdAt: DateTime(year, month, 1),
      ),
      BillModel(
        id: 'bill_demo_003',
        name: 'Internet Bill',
        amount: 799.0,
        category: 'Bills & Utilities',
        dueDate: DateTime(year, month, 10),
        recurrence: BillRecurrence.monthly,
        status: now.day > 10 ? BillStatus.overdue : BillStatus.pending,
        description: 'JioFiber high speed plan',
        createdAt: DateTime(year, month, 1),
      ),
      BillModel(
        id: 'bill_demo_004',
        name: 'Netflix Premium',
        amount: 199.0,
        category: 'Subscriptions',
        dueDate: DateTime(year, month, 15),
        recurrence: BillRecurrence.monthly,
        status: now.day > 15 ? BillStatus.overdue : BillStatus.upcoming,
        description: 'Family 4K plan',
        createdAt: DateTime(year, month, 1),
      ),
      BillModel(
        id: 'bill_demo_005',
        name: 'Health Insurance',
        amount: 12000.0,
        category: 'Health & Fitness',
        dueDate: DateTime(year, month, 25),
        recurrence: BillRecurrence.yearly,
        status: now.day > 25 ? BillStatus.overdue : BillStatus.upcoming,
        description: 'Annual family medical insurance',
        createdAt: DateTime(year, month, 1),
      ),
      BillModel(
        id: 'bill_demo_006',
        name: 'Credit Card Bill',
        amount: 8500.0,
        category: 'Bills & Utilities',
        dueDate: DateTime(year, month, 28),
        recurrence: BillRecurrence.monthly,
        status: BillStatus.upcoming,
        description: 'HDFC Bank Regalia card',
        createdAt: DateTime(year, month, 1),
      ),
    ];
  }

  /// Returns sample budgets for the current month.
  List<BudgetModel> getSampleBudgets() {
    final now = DateTime.now();

    return [
      BudgetModel(
        id: 'budget_demo_001',
        category: 'Overall',
        monthlyLimit: 45000.0,
        month: now.month,
        year: now.year,
        createdAt: DateTime(now.year, now.month, 1),
      ),
      BudgetModel(
        id: 'budget_demo_002',
        category: 'Food & Dining',
        monthlyLimit: 5000.0,
        month: now.month,
        year: now.year,
        createdAt: DateTime(now.year, now.month, 1),
      ),
      BudgetModel(
        id: 'budget_demo_003',
        category: 'Groceries',
        monthlyLimit: 4000.0,
        month: now.month,
        year: now.year,
        createdAt: DateTime(now.year, now.month, 1),
      ),
      BudgetModel(
        id: 'budget_demo_004',
        category: 'Shopping',
        monthlyLimit: 5000.0,
        month: now.month,
        year: now.year,
        createdAt: DateTime(now.year, now.month, 1),
      ),
      BudgetModel(
        id: 'budget_demo_005',
        category: 'Transportation',
        monthlyLimit: 2000.0,
        month: now.month,
        year: now.year,
        createdAt: DateTime(now.year, now.month, 1),
      ),
      BudgetModel(
        id: 'budget_demo_006',
        category: 'Entertainment',
        monthlyLimit: 2000.0,
        month: now.month,
        year: now.year,
        createdAt: DateTime(now.year, now.month, 1),
      ),
    ];
  }

  /// Returns a sample user profile for demo mode.
  UserModel getSampleUser() {
    return UserModel(
      uid: 'demo_user_001',
      fullName: 'Harini',
      email: 'harini@fintrack.app',
      phoneNumber: '+91 98765 43210',
      currencySymbol: '₹',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    );
  }
}
