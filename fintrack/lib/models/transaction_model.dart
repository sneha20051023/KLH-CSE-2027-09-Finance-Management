import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the type of a financial transaction.
enum TransactionType {
  income,
  expense;

  /// Human-readable display name for the transaction type.
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }
}

/// Represents a single financial transaction (income or expense)
/// recorded by the user in the FINTRACK application.
class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String? description;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.description,
    required this.createdAt,
  });

  /// Creates a [TransactionModel] from a Firestore document map.
  /// The [id] parameter is the Firestore document ID, passed separately
  /// since it's not stored inside the document data.
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => TransactionType.expense,
      ),
      category: map['category'] as String? ?? 'Others',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      description: map['description'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this [TransactionModel] to a Firestore-compatible map.
  /// The document ID is not included since Firestore manages it separately.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a copy of this [TransactionModel] with the given fields replaced.
  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? description,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, type: ${type.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
