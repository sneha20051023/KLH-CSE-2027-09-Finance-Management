import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/fraud_alert_model.dart';
import '../models/security_event_model.dart';
import '../models/device_session_model.dart';
import '../models/scam_analysis_model.dart';
import '../models/transaction_model.dart';
import '../services/anomaly_detection_service.dart';
import '../services/scam_scanner_service.dart';

/// Central state provider managing all cybersecurity features, fraud detection,
/// threat monitoring, session management, and audit logging for FINTRACK.
class SecurityProvider extends ChangeNotifier {
  final _anomalyDetector = AnomalyDetectionService();
  final _scamScanner = ScamScannerService();
  final _uuid = const Uuid();

  // ── State Variables ──────────────────────────────────────────────────
  List<FraudAlertModel> _fraudAlerts = [];
  List<SecurityEventModel> _auditLogs = [];
  List<DeviceSessionModel> _activeSessions = [];

  bool _mfaEnabled = true;
  bool _biometricsEnabled = true;
  bool _hideBalances = false;
  bool _autoLockEnabled = true;
  String? _appLockPin = '1234';

  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;

  ScamAnalysisResult? _lastScamResult;
  bool _isScanningScam = false;

  // ── Getters ──────────────────────────────────────────────────────────
  List<FraudAlertModel> get fraudAlerts => List.unmodifiable(_fraudAlerts);
  List<SecurityEventModel> get auditLogs => List.unmodifiable(_auditLogs);
  List<DeviceSessionModel> get activeSessions => List.unmodifiable(_activeSessions);

  bool get mfaEnabled => _mfaEnabled;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get hideBalances => _hideBalances;
  bool get autoLockEnabled => _autoLockEnabled;
  bool get hasAppLockPin => _appLockPin != null;

  int get failedLoginAttempts => _failedLoginAttempts;
  bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  Duration? get remainingLockoutDuration => isLockedOut ? _lockoutUntil!.difference(DateTime.now()) : null;

  ScamAnalysisResult? get lastScamResult => _lastScamResult;
  bool get isScanningScam => _isScanningScam;

  /// Counts of pending / active suspicious alerts
  int get pendingAlertsCount =>
      _fraudAlerts.where((a) => a.status == FraudAlertStatus.pending).length;

  int get highRiskAlertsCount => _fraudAlerts.where((a) {
        return (a.riskLevel == FraudRiskLevel.high || a.riskLevel == FraudRiskLevel.critical) &&
            a.status != FraudAlertStatus.falsePositive;
      }).length;

  /// Deterministically computed Overall Security Score (0 to 100).
  ///
  /// Formula:
  /// - Base score: 50
  /// - MFA enabled: +20
  /// - Biometrics / PIN enabled: +15
  /// - Auto-lock enabled: +10
  /// - Zero failed logins: +5
  /// - Penalty: -15 for each unresolved high/critical alert (max -30)
  /// - Penalty: -5 per recent failed login attempt
  int get securityScore {
    int score = 50;

    if (_mfaEnabled) score += 20;
    if (_biometricsEnabled) score += 15;
    if (_autoLockEnabled) score += 10;
    if (_failedLoginAttempts == 0) score += 5;

    // Deductions for active threats
    final unresolvedThreats = _fraudAlerts.where(
      (a) => (a.riskLevel == FraudRiskLevel.high || a.riskLevel == FraudRiskLevel.critical) &&
          a.status == FraudAlertStatus.pending,
    ).length;
    score -= (unresolvedThreats * 15).clamp(0, 30);
    score -= (_failedLoginAttempts * 5).clamp(0, 20);

    return score.clamp(0, 100);
  }

  /// Human-readable Account Protection Status
  String get protectionStatus {
    final s = securityScore;
    if (s >= 85) return 'Safe & Protected';
    if (s >= 70) return 'Low Risk';
    if (s >= 55) return 'Medium Risk';
    if (s >= 40) return 'High Risk';
    return 'Critical Attention Required';
  }

  SecurityProvider() {
    _loadInitialSecurityData();
  }

  void _loadInitialSecurityData() {
    final now = DateTime.now();

    // 1. Initial Sample Suspicious Alerts (as requested in prompt example)
    _fraudAlerts = [
      FraudAlertModel(
        id: 'alert_001',
        transactionId: 'txn_demo_006',
        transactionTitle: 'Amazon Electronics Spurt',
        amount: 25000.0,
        category: 'Shopping',
        date: now.subtract(const Duration(hours: 14)),
        riskScore: 78,
        riskLevel: FraudRiskLevel.high,
        reasons: [
          'Transaction amount is significantly higher than historical shopping baseline (Avg: ₹3,000).',
          'Single transaction exceeds 4x normal spending deviation.',
        ],
        recommendedAction: 'Verify transaction details to confirm authorized purchase.',
        status: FraudAlertStatus.pending,
        createdAt: now.subtract(const Duration(hours: 14)),
      ),
      FraudAlertModel(
        id: 'alert_002',
        transactionId: 'txn_demo_late',
        transactionTitle: 'Midnight Wire Transfer',
        amount: 12500.0,
        category: 'Others',
        date: now.subtract(const Duration(days: 2, hours: 3)),
        riskScore: 65,
        riskLevel: FraudRiskLevel.medium,
        reasons: [
          'High-value transaction initiated at 02:45 AM (Unusual timing window).',
          'Recipient account has no previous transfer history.',
        ],
        recommendedAction: 'Confirm recipient identity and ensure authorized transaction.',
        status: FraudAlertStatus.reviewed,
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
    ];

    // 2. Initial Sample Active Device Sessions
    _activeSessions = [
      DeviceSessionModel(
        id: 'sess_001',
        deviceName: 'iPhone 17 Pro',
        deviceType: 'Mobile',
        ipAddress: '106.51.78.212',
        location: 'Bengaluru, India',
        lastActive: now,
        isCurrentDevice: true,
      ),
      DeviceSessionModel(
        id: 'sess_002',
        deviceName: 'MacBook Pro 16" (M3)',
        deviceType: 'Desktop',
        ipAddress: '49.207.195.45',
        location: 'Hyderabad, India',
        lastActive: now.subtract(const Duration(hours: 4)),
        isCurrentDevice: false,
      ),
      DeviceSessionModel(
        id: 'sess_003',
        deviceName: 'iPad Air (5th Gen)',
        deviceType: 'Tablet',
        ipAddress: '182.72.10.94',
        location: 'Bengaluru, India',
        lastActive: now.subtract(const Duration(days: 3)),
        isCurrentDevice: false,
      ),
    ];

    // 3. Initial Audit Logs
    _auditLogs = [
      SecurityEventModel(
        id: 'log_001',
        type: SecurityEventType.successfulLogin,
        description: 'Biometric fingerprint login verified on current device.',
        timestamp: now.subtract(const Duration(minutes: 12)),
        severity: SecuritySeverity.info,
        ipAddress: '106.51.78.212',
        deviceName: 'iPhone 17 Pro',
      ),
      SecurityEventModel(
        id: 'log_002',
        type: SecurityEventType.suspiciousTransactionDetected,
        description: 'Anomaly Engine flagged ₹25,000 Shopping transaction as High Risk.',
        timestamp: now.subtract(const Duration(hours: 14)),
        severity: SecuritySeverity.warning,
        ipAddress: '106.51.78.212',
        deviceName: 'iPhone 17 Pro',
      ),
      SecurityEventModel(
        id: 'log_003',
        type: SecurityEventType.mfaToggled,
        description: 'Two-Factor Authentication (2FA) policy confirmed active.',
        timestamp: now.subtract(const Duration(days: 1)),
        severity: SecuritySeverity.info,
        ipAddress: '106.51.78.212',
        deviceName: 'iPhone 17 Pro',
      ),
      SecurityEventModel(
        id: 'log_004',
        type: SecurityEventType.failedLogin,
        description: 'Failed password attempt detected from unverified IP 115.242.8.10.',
        timestamp: now.subtract(const Duration(days: 3)),
        severity: SecuritySeverity.critical,
        ipAddress: '115.242.8.10',
        deviceName: 'Unknown Chrome Browser',
      ),
    ];
  }

  // ===========================================================================
  // REAL-TIME TRANSACTION EVALUATION
  // ===========================================================================

  /// Evaluates an incoming transaction against historical data using
  /// the [AnomalyDetectionService].
  void inspectTransaction({
    required TransactionModel transaction,
    required List<TransactionModel> history,
  }) {
    final alert = _anomalyDetector.evaluateTransaction(
      candidateTx: transaction,
      historicalTransactions: history,
    );

    if (alert != null) {
      _fraudAlerts.insert(0, alert);
      logEvent(
        type: SecurityEventType.suspiciousTransactionDetected,
        description: 'Potentially Suspicious Transaction of ₹${transaction.amount.toStringAsFixed(0)} in ${transaction.category} flagged (Risk Score: ${alert.riskScore}).',
        severity: alert.riskLevel == FraudRiskLevel.critical
            ? SecuritySeverity.critical
            : SecuritySeverity.warning,
      );
      notifyListeners();
    }
  }

  /// Updates the review status of an alert (Reviewed, Confirmed, False Positive).
  void updateAlertStatus(String alertId, FraudAlertStatus status) {
    final index = _fraudAlerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _fraudAlerts[index] = _fraudAlerts[index].copyWith(status: status);
      logEvent(
        type: SecurityEventType.suspiciousTransactionDetected,
        description: 'Alert "${_fraudAlerts[index].transactionTitle}" updated to ${status.displayName}.',
        severity: SecuritySeverity.info,
      );
      notifyListeners();
    }
  }

  // ===========================================================================
  // BRUTE-FORCE & LOGIN SECURITY
  // ===========================================================================

  void recordFailedLogin(String ip) {
    _failedLoginAttempts++;
    logEvent(
      type: SecurityEventType.failedLogin,
      description: 'Failed authentication attempt recorded (Count: $_failedLoginAttempts).',
      severity: SecuritySeverity.warning,
      ipAddress: ip,
    );

    // Apply temporary lockout if >= 5 failed attempts
    if (_failedLoginAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(minutes: 15));
      logEvent(
        type: SecurityEventType.accountLocked,
        description: 'Brute-force protection: Temporary account lockout triggered for 15 minutes.',
        severity: SecuritySeverity.critical,
        ipAddress: ip,
      );
    }
    notifyListeners();
  }

  void resetFailedLogins() {
    _failedLoginAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();
  }

  // ===========================================================================
  // SESSION MANAGEMENT
  // ===========================================================================

  void terminateSession(String sessionId) {
    final session = _activeSessions.firstWhere((s) => s.id == sessionId, orElse: () => _activeSessions.first);
    _activeSessions.removeWhere((s) => s.id == sessionId);
    logEvent(
      type: SecurityEventType.sessionTerminated,
      description: 'Active session "${session.deviceName}" terminated remotely.',
      severity: SecuritySeverity.info,
      ipAddress: session.ipAddress,
      deviceName: session.deviceName,
    );
    notifyListeners();
  }

  void terminateAllOtherSessions() {
    _activeSessions.removeWhere((s) => !s.isCurrentDevice);
    logEvent(
      type: SecurityEventType.sessionTerminated,
      description: 'All secondary sessions terminated remotely.',
      severity: SecuritySeverity.warning,
    );
    notifyListeners();
  }

  // ===========================================================================
  // SECURITY AUDIT LOGGING
  // ===========================================================================

  void logEvent({
    required SecurityEventType type,
    required String description,
    required SecuritySeverity severity,
    String? ipAddress,
    String? deviceName,
  }) {
    final event = SecurityEventModel(
      id: 'log_${_uuid.v4().substring(0, 8)}',
      type: type,
      description: description,
      timestamp: DateTime.now(),
      severity: severity,
      ipAddress: ipAddress ?? '106.51.78.212',
      deviceName: deviceName ?? 'iPhone 17 Pro',
    );
    _auditLogs.insert(0, event);
    notifyListeners();
  }

  // ===========================================================================
  // PHISHING & SCAM SCANNER
  // ===========================================================================

  Future<void> scanScamInput(String input) async {
    _isScanningScam = true;
    notifyListeners();

    // Short processing delay for realistic ML scanning experience
    await Future.delayed(const Duration(milliseconds: 400));
    _lastScamResult = _scamScanner.analyze(input);
    _isScanningScam = false;

    if (_lastScamResult != null && _lastScamResult!.isSuspicious) {
      logEvent(
        type: SecurityEventType.suspiciousTransactionDetected,
        description: 'Phishing scanner detected high risk text/link: "${_lastScamResult!.detectedTriggers.first}".',
        severity: SecuritySeverity.warning,
      );
    }
    notifyListeners();
  }

  void clearScamResult() {
    _lastScamResult = null;
    notifyListeners();
  }

  // ===========================================================================
  // SECURITY TOGGLES
  // ===========================================================================

  void toggleMfa(bool value) {
    _mfaEnabled = value;
    logEvent(
      type: SecurityEventType.mfaToggled,
      description: value ? 'Two-Factor Authentication (2FA) enabled.' : 'Two-Factor Authentication (2FA) disabled.',
      severity: value ? SecuritySeverity.info : SecuritySeverity.warning,
    );
    notifyListeners();
  }

  void toggleBiometrics(bool value) {
    _biometricsEnabled = value;
    notifyListeners();
  }

  void togglePrivacyMode(bool value) {
    _hideBalances = value;
    logEvent(
      type: SecurityEventType.privacyModeToggled,
      description: value ? 'Privacy Mode enabled (Financial amounts masked).' : 'Privacy Mode disabled (Financial amounts visible).',
      severity: SecuritySeverity.info,
    );
    notifyListeners();
  }

  void toggleAutoLock(bool value) {
    _autoLockEnabled = value;
    notifyListeners();
  }
}

