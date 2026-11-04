import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Risk level classification for transactions.
enum FraudRiskLevel {
  safe,
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case FraudRiskLevel.safe:
        return 'Safe';
      case FraudRiskLevel.low:
        return 'Low Risk';
      case FraudRiskLevel.medium:
        return 'Medium Risk';
      case FraudRiskLevel.high:
        return 'High Risk';
      case FraudRiskLevel.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case FraudRiskLevel.safe:
        return AppColors.income;
      case FraudRiskLevel.low:
        return const Color(0xFF4A90E2);
      case FraudRiskLevel.medium:
        return AppColors.warning;
      case FraudRiskLevel.high:
        return AppColors.roseAccent;
      case FraudRiskLevel.critical:
        return AppColors.error;
    }
  }

  Color get containerColor {
    switch (this) {
      case FraudRiskLevel.safe:
        return AppColors.pastelMint;
      case FraudRiskLevel.low:
        return const Color(0xFFE8F1FC);
      case FraudRiskLevel.medium:
        return AppColors.lightPeach;
      case FraudRiskLevel.high:
        return AppColors.softBlush;
      case FraudRiskLevel.critical:
        return const Color(0xFFFFE0E3);
    }
  }
}

/// User review state of a potentially suspicious alert.
enum FraudAlertStatus {
  pending,
  reviewed,
  confirmedSuspicious,
  falsePositive;

  String get displayName {
    switch (this) {
      case FraudAlertStatus.pending:
        return 'Pending Review';
      case FraudAlertStatus.reviewed:
        return 'Reviewed';
      case FraudAlertStatus.confirmedSuspicious:
        return 'Confirmed Suspicious';
      case FraudAlertStatus.falsePositive:
        return 'False Positive (Safe)';
    }
  }
}

/// Represents a Potentially Suspicious Transaction alert generated
/// by the Anomaly Detection Engine.
class FraudAlertModel {
  final String id;
  final String transactionId;
  final String transactionTitle;
  final double amount;
  final String category;
  final DateTime date;
  final int riskScore; // 0 to 100
  final FraudRiskLevel riskLevel;
  final List<String> reasons;
  final String recommendedAction;
  final FraudAlertStatus status;
  final DateTime createdAt;

  const FraudAlertModel({
    required this.id,
    required this.transactionId,
    required this.transactionTitle,
    required this.amount,
    required this.category,
    required this.date,
    required this.riskScore,
    required this.riskLevel,
    required this.reasons,
    required this.recommendedAction,
    this.status = FraudAlertStatus.pending,
    required this.createdAt,
  });

  FraudAlertModel copyWith({
    String? id,
    String? transactionId,
    String? transactionTitle,
    double? amount,
    String? category,
    DateTime? date,
    int? riskScore,
    FraudRiskLevel? riskLevel,
    List<String>? reasons,
    String? recommendedAction,
    FraudAlertStatus? status,
    DateTime? createdAt,
  }) {
    return FraudAlertModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      transactionTitle: transactionTitle ?? this.transactionTitle,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      reasons: reasons ?? this.reasons,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'transactionTitle': transactionTitle,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'riskScore': riskScore,
      'riskLevel': riskLevel.name,
      'reasons': reasons,
      'recommendedAction': recommendedAction,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FraudAlertModel.fromMap(Map<String, dynamic> map) {
    return FraudAlertModel(
      id: map['id'] as String,
      transactionId: map['transactionId'] as String,
      transactionTitle: map['transactionTitle'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      riskScore: map['riskScore'] as int,
      riskLevel: FraudRiskLevel.values.firstWhere(
        (e) => e.name == map['riskLevel'],
        orElse: () => FraudRiskLevel.low,
      ),
      reasons: List<String>.from(map['reasons'] as List),
      recommendedAction: map['recommendedAction'] as String,
      status: FraudAlertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FraudAlertStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

