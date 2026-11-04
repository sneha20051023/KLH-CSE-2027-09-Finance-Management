import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents how frequently a bill recurs.
enum BillRecurrence {
  oneTime,
  weekly,
  monthly,
  yearly;

  /// Human-readable display name for the recurrence type.
  String get displayName {
    switch (this) {
      case BillRecurrence.oneTime:
        return 'One Time';
      case BillRecurrence.weekly:
        return 'Weekly';
      case BillRecurrence.monthly:
        return 'Monthly';
      case BillRecurrence.yearly:
        return 'Yearly';
    }
  }
}

/// Represents the current payment status of a bill.
enum BillStatus {
  upcoming,
  pending,
  paid,
  overdue;

  /// Human-readable display name for the bill status.
  String get displayName {
    switch (this) {
      case BillStatus.upcoming:
        return 'Upcoming';
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.overdue:
        return 'Overdue';
    }
  }

  /// Color associated with each bill status for pastel UI indicators.
  Color get color {
    switch (this) {
      case BillStatus.upcoming:
        return const Color(0xFF9ED2C6); // Pastel Seafoam
      case BillStatus.pending:
        return const Color(0xFFF8A978); // Pastel Peach
      case BillStatus.paid:
        return const Color(0xFF38A169); // Soft Mint Green
      case BillStatus.overdue:
        return const Color(0xFFE05375); // Soft Rose Alert
    }
  }
}

/// Represents a recurring or one-time bill/payment reminder
/// in the FINTRACK application.
class BillModel {
  final String id;
  final String name;
  final double amount;
  final String category;
  final DateTime dueDate;
  final BillRecurrence recurrence;
  final BillStatus status;
  final String? description;

  /// Links to the transaction created when the bill is marked as paid.
  /// Prevents duplicate transactions from being created.
  final String? linkedTransactionId;
  final DateTime createdAt;

  const BillModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.dueDate,
    required this.recurrence,
    required this.status,
    this.description,
    this.linkedTransactionId,
    required this.createdAt,
  });

  /// Whether this bill is overdue — past due date and not yet paid.
  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != BillStatus.paid;

  /// Creates a [BillModel] from a Firestore document map.
  /// The [id] parameter is the Firestore document ID, passed separately
  /// since it's not stored inside the document data.
  factory BillModel.fromMap(Map<String, dynamic> map, String id) {
    return BillModel(
      id: id,
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Others',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recurrence: BillRecurrence.values.firstWhere(
        (e) => e.name == (map['recurrence'] as String?),
        orElse: () => BillRecurrence.oneTime,
      ),
      status: BillStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => BillStatus.upcoming,
      ),
      description: map['description'] as String?,
      linkedTransactionId: map['linkedTransactionId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this [BillModel] to a Firestore-compatible map.
  /// The document ID is not included since Firestore manages it separately.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'dueDate': Timestamp.fromDate(dueDate),
      'recurrence': recurrence.name,
      'status': status.name,
      'description': description,
      'linkedTransactionId': linkedTransactionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a copy of this [BillModel] with the given fields replaced.
  BillModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    DateTime? dueDate,
    BillRecurrence? recurrence,
    BillStatus? status,
    String? description,
    String? linkedTransactionId,
    DateTime? createdAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      status: status ?? this.status,
      description: description ?? this.description,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'BillModel(id: $id, name: $name, amount: $amount, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BillModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
