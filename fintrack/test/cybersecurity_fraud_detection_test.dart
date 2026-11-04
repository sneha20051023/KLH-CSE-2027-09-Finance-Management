import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/models/transaction_model.dart';
import 'package:fintrack/models/fraud_alert_model.dart';
import 'package:fintrack/services/anomaly_detection_service.dart';
import 'package:fintrack/services/scam_scanner_service.dart';
import 'package:fintrack/providers/security_provider.dart';

void main() {
  group('Cybersecurity Fraud & Anomaly Detection Unit Tests', () {
    late AnomalyDetectionService anomalyDetector;
    late ScamScannerService scamScanner;
    late SecurityProvider securityProvider;

    setUp(() {
      anomalyDetector = AnomalyDetectionService();
      scamScanner = ScamScannerService();
      securityProvider = SecurityProvider();
    });

    test('Normal transaction within baseline is evaluated as clean', () {
      final List<TransactionModel> history = [
        TransactionModel(
          id: '1',
          title: 'Grocery Store',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Groceries',
          date: DateTime.now().subtract(const Duration(days: 1)),
          paymentMethod: 'UPI',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        TransactionModel(
          id: '2',
          title: 'Supermarket',
          amount: 1800.0,
          type: TransactionType.expense,
          category: 'Groceries',
          date: DateTime.now().subtract(const Duration(days: 2)),
          paymentMethod: 'UPI',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      final candidate = TransactionModel(
        id: 'candidate_normal',
        title: 'Daily Milk & Bread',
        amount: 1600.0,
        type: TransactionType.expense,
        category: 'Groceries',
        date: DateTime.now(),
        paymentMethod: 'UPI',
        createdAt: DateTime.now(),
      );

      final alert = anomalyDetector.evaluateTransaction(
        candidateTx: candidate,
        historicalTransactions: history,
      );

      expect(alert, isNull);
    });

    test('Massive spike transaction (> 10x baseline) triggers High Risk Fraud Alert', () {
      final List<TransactionModel> history = [
        TransactionModel(
          id: '1',
          title: 'Shirt',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime.now().subtract(const Duration(days: 1)),
          paymentMethod: 'UPI',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        TransactionModel(
          id: '2',
          title: 'Shoes',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime.now().subtract(const Duration(days: 2)),
          paymentMethod: 'UPI',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        TransactionModel(
          id: '3',
          title: 'Jacket',
          amount: 2000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime.now().subtract(const Duration(days: 3)),
          paymentMethod: 'UPI',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

      final candidate = TransactionModel(
        id: 'candidate_fraud_spike',
        title: 'Luxury Jewelry',
        amount: 85000.0,
        type: TransactionType.expense,
        category: 'Shopping',
        date: DateTime.now(),
        paymentMethod: 'UPI',
        createdAt: DateTime.now(),
      );

      final alert = anomalyDetector.evaluateTransaction(
        candidateTx: candidate,
        historicalTransactions: history,
      );

      expect(alert, isNotNull);
      expect(alert!.riskScore, greaterThanOrEqualTo(70));
      expect(
        alert.riskLevel == FraudRiskLevel.high || alert.riskLevel == FraudRiskLevel.critical,
        isTrue,
      );
      expect(alert.reasons, isNotEmpty);
    });

    test('Scam scanner flags electricity bill suspension phishing message', () {
      const maliciousSms =
          'Dear customer your electricity power will be disconnected tonight at 9:30 PM due to unpaid bill. Immediately update KYC or call 9876543210.';

      final analysis = scamScanner.analyze(maliciousSms);

      expect(analysis.isSuspicious, isTrue);
      expect(analysis.confidenceScore, greaterThanOrEqualTo(50));
      expect(analysis.detectedTriggers, isNotEmpty);
    });

    test('Scam scanner marks standard benign text as safe', () {
      const safeText = 'Hey Sneha, can you send me the lecture notes for ML capstone? Thanks!';

      final analysis = scamScanner.analyze(safeText);

      expect(analysis.isSuspicious, isFalse);
      expect(analysis.confidenceScore, lessThan(40));
    });

    test('Deterministic Security Score starts between 0 and 100 based on active policies', () {
      final initialScore = securityProvider.securityScore;
      expect(initialScore, inInclusiveRange(0, 100));

      final initialStatus = securityProvider.protectionStatus;
      expect(initialStatus, isNotEmpty);
    });

    test('Brute force defense enforces temporary lockout after 5 consecutive failures', () {
      expect(securityProvider.isLockedOut, isFalse);

      for (int i = 0; i < 4; i++) {
        securityProvider.recordFailedLogin('192.168.1.100');
        expect(securityProvider.isLockedOut, isFalse);
      }

      // 5th failed login triggers lockout
      securityProvider.recordFailedLogin('192.168.1.100');
      expect(securityProvider.isLockedOut, isTrue);
      expect(securityProvider.failedLoginAttempts, equals(5));

      // Reset restores access
      securityProvider.resetFailedLogins();
      expect(securityProvider.isLockedOut, isFalse);
      expect(securityProvider.failedLoginAttempts, equals(0));
    });

    test('Remote session termination cleanly evicts device and logs audit event', () {
      final initialCount = securityProvider.activeSessions.length;
      expect(initialCount, greaterThan(0));

      final sessionToKill = securityProvider.activeSessions.firstWhere((s) => !s.isCurrentDevice);
      securityProvider.terminateSession(sessionToKill.id);

      expect(
        securityProvider.activeSessions.any((s) => s.id == sessionToKill.id),
        isFalse,
      );
      expect(securityProvider.auditLogs.first.description, contains('terminated remotely'));
    });
  });
}
