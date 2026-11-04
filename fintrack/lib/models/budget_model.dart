import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a monthly budget limit for a specific category or overall spending
/// in the FINTRACK application.
class BudgetModel {
  final String id;

  /// The expense category this budget applies to.
  /// Use 'Overall' for the total monthly budget across all categories.
  final String category;
  final double monthlyLimit;
  final int month;
  final int year;
  final DateTime createdAt;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  /// Returns the percentage of the budget that has been used.
  /// Clamped between 0 and 999 to prevent UI overflow issues.
  double percentUsed(double spent) =>
      (spent / monthlyLimit * 100).clamp(0, 999);

  /// Returns how much of the budget remains after the given spending.
  /// Can be negative if overspent.
  double remaining(double spent) => monthlyLimit - spent;

  /// Whether spending has exceeded the budget limit.
  bool isOverBudget(double spent) => spent > monthlyLimit;

  /// Whether spending is at or above 80% of the budget limit.
  /// Used to trigger warning indicators in the UI.
  bool isNearLimit(double spent) => spent >= monthlyLimit * 0.8;

  /// Creates a [BudgetModel] from a Firestore document map.
  /// The [id] parameter is the Firestore document ID, passed separately
  /// since it's not stored inside the document data.
  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      category: map['category'] as String? ?? 'Overall',
      monthlyLimit: (map['monthlyLimit'] as num?)?.toDouble() ?? 0.0,
      month: map['month'] as int? ?? DateTime.now().month,
      year: map['year'] as int? ?? DateTime.now().year,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this [BudgetModel] to a Firestore-compatible map.
  /// The document ID is not included since Firestore manages it separately.
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'monthlyLimit': monthlyLimit,
      'month': month,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a copy of this [BudgetModel] with the given fields replaced.
  BudgetModel copyWith({
    String? id,
    String? category,
    double? monthlyLimit,
    int? month,
    int? year,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'BudgetModel(id: $id, category: $category, limit: $monthlyLimit, month: $month/$year)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
