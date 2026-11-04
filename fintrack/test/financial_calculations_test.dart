import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/models/transaction_model.dart';
import 'package:fintrack/models/budget_model.dart';
import 'package:fintrack/models/bill_model.dart';
import 'package:fintrack/utils/helpers.dart';

void main() {
  group('FINTRACK Financial Calculation Tests', () {
    test('Total Balance = Total Income - Total Expenses', () {
      final transactions = [
        TransactionModel(
          id: '1',
          title: 'Salary',
          amount: 60000.0,
          type: TransactionType.income,
          category: 'Salary',
          date: DateTime.now(),
          paymentMethod: 'Net Banking',
          createdAt: DateTime.now(),
        ),
        TransactionModel(
          id: '2',
          title: 'Grocery',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Groceries',
          date: DateTime.now(),
          paymentMethod: 'UPI',
          createdAt: DateTime.now(),
        ),
        TransactionModel(
          id: '3',
          title: 'Rent',
          amount: 15000.0,
          type: TransactionType.expense,
          category: 'Housing & Rent',
          date: DateTime.now(),
          paymentMethod: 'Net Banking',
          createdAt: DateTime.now(),
        ),
      ];

      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalExpenses = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalBalance = totalIncome - totalExpenses;

      expect(totalIncome, 60000.0);
      expect(totalExpenses, 17500.0);
      expect(totalBalance, 42500.0);
    });

    test('Budget limit and threshold helpers work correctly', () {
      final budget = BudgetModel(
        id: 'b1',
        category: 'Food & Dining',
        monthlyLimit: 5000.0,
        month: 10,
        year: 2026,
        createdAt: DateTime.now(),
      );

      expect(budget.percentUsed(2500.0), 50.0);
      expect(budget.remaining(2500.0), 2500.0);
      expect(budget.isOverBudget(2500.0), false);
      expect(budget.isNearLimit(2500.0), false);

      // 80% warning threshold (4000 spent)
      expect(budget.isNearLimit(4000.0), true);
      expect(budget.isOverBudget(4000.0), false);

      // Over budget (5500 spent)
      expect(budget.isOverBudget(5500.0), true);
      expect(budget.remaining(5500.0), -500.0);
    });

    test('Bill status and recurrence display correctly', () {
      final bill = BillModel(
        id: 'bill1',
        name: 'Internet',
        amount: 799.0,
        category: 'Bills & Utilities',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        recurrence: BillRecurrence.monthly,
        status: BillStatus.upcoming,
        createdAt: DateTime.now(),
      );

      expect(bill.recurrence.displayName, 'Monthly');
      expect(bill.status.displayName, 'Upcoming');
      expect(bill.isOverdue, false);
    });

    test('Format currency handles Indian numbering format', () {
      final formatted = formatCurrency(60000.0);
      expect(formatted.contains('₹'), true);
      expect(formatted.contains('60,000'), true);
    });
  });
}

