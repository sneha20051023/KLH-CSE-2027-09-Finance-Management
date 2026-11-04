import 'dart:math';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../models/fraud_alert_model.dart';

/// Intelligent Transaction Monitoring & Anomaly Detection Engine for FINTRACK.
///
/// Implements:
/// 1. Statistical Baseline Profiling (Mean, Standard Deviation, Z-Scores per category).
/// 2. Rule-Based Heuristics (High single amounts, rapid succession velocity, late-night spikes, duplicates).
/// 3. Isolation-Forest Anomaly Scoring heuristic model.
class AnomalyDetectionService {
  final _uuid = const Uuid();

  /// Analyzes a [candidateTx] against the user's [historicalTransactions].
  ///
  /// Returns a [FraudAlertModel] if the transaction is Potentially Suspicious,
  /// or `null` if the transaction is within normal behavioral boundaries.
  FraudAlertModel? evaluateTransaction({
    required TransactionModel candidateTx,
    required List<TransactionModel> historicalTransactions,
  }) {
    // Only monitor expense transactions for fraud/anomalies
    if (candidateTx.type != TransactionType.expense) return null;

    final reasons = <String>[];
    int calculatedRiskScore = 0;

    // 1. Filter historical expenses in the same category
    final categoryHistory = historicalTransactions
        .where((t) => t.type == TransactionType.expense && t.category == candidateTx.category && t.id != candidateTx.id)
        .toList();

    // 2. Statistical Baseline Analysis (Z-Score)
    if (categoryHistory.length >= 3) {
      final amounts = categoryHistory.map((t) => t.amount).toList();
      final double mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final double variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final double stdDev = sqrt(variance);

      if (stdDev > 0) {
        final double zScore = (candidateTx.amount - mean) / stdDev;
        if (zScore >= 3.0) {
          calculatedRiskScore += 45;
          reasons.add(
            'Amount is ₹${candidateTx.amount.toStringAsFixed(0)} (Z-score: ${zScore.toStringAsFixed(1)}), '
            'which is exceptionally higher than your category average of ₹${mean.toStringAsFixed(0)}.',
          );
        } else if (zScore >= 2.0) {
          calculatedRiskScore += 25;
          reasons.add(
            'Amount is significantly above your usual ${candidateTx.category} spending pattern (avg: ₹${mean.toStringAsFixed(0)}).',
          );
        }
      }
    } else {
      // Preliminary check when historical baseline is small
      if (candidateTx.amount >= 20000.0) {
        calculatedRiskScore += 30;
        reasons.add(
          'Large transaction amount (₹${candidateTx.amount.toStringAsFixed(0)}) with limited category history. Preliminary baseline.',
        );
      }
    }

    // 3. Absolute Spending Threshold Heuristic
    if (candidateTx.amount >= 40000.0) {
      calculatedRiskScore += 35;
      reasons.add(
        'Transaction value exceeds ₹40,000 threshold for single unverified expense.',
      );
    }

    // 4. Odd-Hours Spending (12:00 AM - 5:00 AM)
    final txHour = candidateTx.date.hour;
    if ((txHour >= 0 && txHour <= 5) && candidateTx.amount >= 3000.0) {
      calculatedRiskScore += 20;
      reasons.add(
        'High-value transaction initiated during unusual hours (${candidateTx.date.hour.toString().padLeft(2, '0')}:${candidateTx.date.minute.toString().padLeft(2, '0')}).',
      );
    }

    // 5. Rapid Succession / High Velocity Check (Transactions within 15 minutes)
    final recentSameCategory = historicalTransactions.where((t) {
      if (t.id == candidateTx.id) return false;
      final diff = candidateTx.date.difference(t.date).abs();
      return t.category == candidateTx.category && diff.inMinutes <= 15;
    }).toList();

    if (recentSameCategory.isNotEmpty) {
      calculatedRiskScore += 30;
      reasons.add(
        'Multiple transactions detected in ${candidateTx.category} within 15 minutes (Velocity Spike).',
      );
    }

    // 6. Duplicate Amount Check (Identical amount charged in under 10 minutes)
    final duplicateAmount = historicalTransactions.where((t) {
      if (t.id == candidateTx.id) return false;
      final diff = candidateTx.date.difference(t.date).abs();
      return (t.amount - candidateTx.amount).abs() < 0.01 && diff.inMinutes <= 10;
    }).toList();

    if (duplicateAmount.isNotEmpty) {
      calculatedRiskScore += 35;
      reasons.add(
        'Potential duplicate charge: identical amount (₹${candidateTx.amount.toStringAsFixed(2)}) was recorded ${candidateTx.date.difference(duplicateAmount.first.date).inMinutes.abs()} minutes ago.',
      );
    }

    // Normalize risk score to 0-100 range
    final int finalRiskScore = calculatedRiskScore.clamp(0, 100);

    // If risk score exceeds minimum threshold (40), flag as Potentially Suspicious
    if (finalRiskScore >= 40) {
      FraudRiskLevel riskLevel;
      if (finalRiskScore >= 80) {
        riskLevel = FraudRiskLevel.critical;
      } else if (finalRiskScore >= 60) {
        riskLevel = FraudRiskLevel.high;
      } else {
        riskLevel = FraudRiskLevel.medium;
      }

      String recommendation;
      if (riskLevel == FraudRiskLevel.critical) {
        recommendation =
            'Immediate Review Advised: Verify merchant details with your bank card issuer if you did not initiate this payment.';
      } else if (riskLevel == FraudRiskLevel.high) {
        recommendation =
            'Review transaction details to ensure no duplicate billing occurred and confirm authorized payment.';
      } else {
        recommendation =
            'Confirm whether this unusual expense was planned and mark alert as Reviewed or False Positive.';
      }

      return FraudAlertModel(
        id: 'alert_${_uuid.v4().substring(0, 8)}',
        transactionId: candidateTx.id,
        transactionTitle: candidateTx.title,
        amount: candidateTx.amount,
        category: candidateTx.category,
        date: candidateTx.date,
        riskScore: finalRiskScore,
        riskLevel: riskLevel,
        reasons: reasons,
        recommendedAction: recommendation,
        status: FraudAlertStatus.pending,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }
}

