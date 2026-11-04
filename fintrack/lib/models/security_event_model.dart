import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Categories of security audit events logged in FINTRACK.
enum SecurityEventType {
  successfulLogin,
  failedLogin,
  passwordChange,
  mfaToggled,
  newDeviceLogin,
  suspiciousTransactionDetected,
  sessionTerminated,
  budgetModified,
  accountLocked,
  privacyModeToggled,
}

/// Severity classification for security events.
enum SecuritySeverity {
  info,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case SecuritySeverity.info:
        return 'Safe / Info';
      case SecuritySeverity.warning:
        return 'Warning';
      case SecuritySeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case SecuritySeverity.info:
        return AppColors.income;
      case SecuritySeverity.warning:
        return AppColors.warning;
      case SecuritySeverity.critical:
        return AppColors.error;
    }
  }

  Color get containerColor {
    switch (this) {
      case SecuritySeverity.info:
        return AppColors.pastelMint;
      case SecuritySeverity.warning:
        return AppColors.lightPeach;
      case SecuritySeverity.critical:
        return AppColors.softBlush;
    }
  }
}

/// Represents an immutable audit log entry for cybersecurity tracking.
class SecurityEventModel {
  final String id;
  final SecurityEventType type;
  final String description;
  final DateTime timestamp;
  final SecuritySeverity severity;
  final String? ipAddress;
  final String? deviceName;
  final bool isReviewed;

  const SecurityEventModel({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.severity,
    this.ipAddress,
    this.deviceName,
    this.isReviewed = false,
  });

  SecurityEventModel copyWith({
    String? id,
    SecurityEventType? type,
    String? description,
    DateTime? timestamp,
    SecuritySeverity? severity,
    String? ipAddress,
    String? deviceName,
    bool? isReviewed,
  }) {
    return SecurityEventModel(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      severity: severity ?? this.severity,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceName: deviceName ?? this.deviceName,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  IconData get icon {
    switch (type) {
      case SecurityEventType.successfulLogin:
        return Icons.login_rounded;
      case SecurityEventType.failedLogin:
        return Icons.no_accounts_rounded;
      case SecurityEventType.passwordChange:
        return Icons.lock_reset_rounded;
      case SecurityEventType.mfaToggled:
        return Icons.verified_user_rounded;
      case SecurityEventType.newDeviceLogin:
        return Icons.devices_other_rounded;
      case SecurityEventType.suspiciousTransactionDetected:
        return Icons.gpp_bad_rounded;
      case SecurityEventType.sessionTerminated:
        return Icons.phonelink_erase_rounded;
      case SecurityEventType.budgetModified:
        return Icons.tune_rounded;
      case SecurityEventType.accountLocked:
        return Icons.security_rounded;
      case SecurityEventType.privacyModeToggled:
        return Icons.visibility_off_rounded;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'ipAddress': ipAddress,
      'deviceName': deviceName,
      'isReviewed': isReviewed,
    };
  }

  factory SecurityEventModel.fromMap(Map<String, dynamic> map) {
    return SecurityEventModel(
      id: map['id'] as String,
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SecurityEventType.successfulLogin,
      ),
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      severity: SecuritySeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => SecuritySeverity.info,
      ),
      ipAddress: map['ipAddress'] as String?,
      deviceName: map['deviceName'] as String?,
      isReviewed: map['isReviewed'] as bool? ?? false,
    );
  }
}

