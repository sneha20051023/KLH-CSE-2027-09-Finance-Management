import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/fraud_alert_model.dart';
import '../../models/security_event_model.dart';
import '../../models/device_session_model.dart';
import '../../providers/security_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// The Central Cybersecurity Module of the FINTRACK framework:
/// - Security Score (0–100) with transparent rule-based scoring
/// - Account protection status & threat indicators
/// - Suspicious Transaction Anomaly Alerts with explainability
/// - Phishing & Financial Scam Analyzer
/// - Active Device & Session Management
/// - Security Audit Logging feed
class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  final _scamTextController = TextEditingController();

  @override
  void dispose() {
    _scamTextController.dispose();
    super.dispose();
  }

  void _showScamScannerSheet(BuildContext context, SecurityProvider security) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final result = security.lastScamResult;
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.softBlush,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.travel_explore_rounded, color: AppColors.roseAccent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Phishing & Scam Scanner',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Analyze suspicious payment requests, SMS alerts, or links without opening them.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _scamTextController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Paste suspicious message or URL (e.g. "Dear customer, your SBI card is blocked. Click here to verify OTP...")',
                      hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: security.isScanningScam
                              ? null
                              : () async {
                                  if (_scamTextController.text.trim().isEmpty) return;
                                  await security.scanScamInput(_scamTextController.text);
                                  setSheetState(() {});
                                },
                          icon: security.isScanningScam
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.security_update_good_rounded, size: 18),
                          label: Text(security.isScanningScam ? 'Analyzing...' : 'Scan for Threats'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.roseAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      if (result != null) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            _scamTextController.clear();
                            security.clearScamResult();
                            setSheetState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textLight,
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ],
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: result.riskLevel.containerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: result.riskLevel.color.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Scan Result: ${result.riskLevel.displayName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: result.riskLevel.color,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Risk Score: ${result.confidenceScore}/100',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: result.riskLevel.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.explanation,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Detected Indicators:',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          const SizedBox(height: 4),
                          ...result.detectedTriggers.map(
                            (trig) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.arrow_right_rounded, size: 18, color: AppColors.roseAccent),
                                  Expanded(
                                    child: Text(
                                      trig,
                                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.text),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    result.recommendation,
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSessionDetails(BuildContext context, SecurityProvider security) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.devices_rounded, color: AppColors.roseAccent),
                    const SizedBox(width: 10),
                    Text(
                      'Active Device Sessions',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    security.terminateAllOtherSessions();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Logout Others',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...security.activeSessions.map((sess) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sess.isCurrentDevice ? AppColors.softBlush : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sess.isCurrentDevice ? AppColors.roseAccent.withOpacity(0.5) : AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(sess.icon, color: AppColors.roseAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(sess.deviceName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                              if (sess.isCurrentDevice) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.roseAccent, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('THIS DEVICE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          Text('${sess.location} • IP: ${sess.ipAddress}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                          Text('Last active: ${formatDate(sess.lastActive)}', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (!sess.isCurrentDevice)
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.expense, size: 20),
                        tooltip: 'Terminate Session',
                        onPressed: () {
                          security.terminateSession(sess.id);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    final score = security.securityScore;
    final status = security.protectionStatus;
    final alerts = security.fraudAlerts;
    final auditLogs = security.auditLogs;

    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.income;
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Security Center',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              security.hideBalances ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.roseAccent,
            ),
            tooltip: security.hideBalances ? 'Privacy Mode ON' : 'Privacy Mode OFF',
            onPressed: () => security.togglePrivacyMode(!security.hideBalances),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 90),
            children: [
              // 1. Overall Security Score Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF4F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.roseAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated Circular Score Gauge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 82,
                          height: 82,
                          child: CircularProgressIndicator(
                            value: score / 100.0,
                            strokeWidth: 8,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              '/100',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scoreColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Account Security Score',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'Computed dynamically from MFA status, login attempt health, and active fraud anomalies.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Security KPI Metric Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Suspicious Alerts',
                        value: '${security.pendingAlertsCount}',
                        icon: Icons.notification_important_rounded,
                        color: security.pendingAlertsCount > 0 ? AppColors.expense : AppColors.income,
                        bgColor: security.pendingAlertsCount > 0 ? AppColors.softBlush : AppColors.pastelMint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Failed Logins',
                        value: '${security.failedLoginAttempts}',
                        icon: Icons.no_accounts_rounded,
                        color: security.failedLoginAttempts > 0 ? AppColors.warning : AppColors.income,
                        bgColor: security.failedLoginAttempts > 0 ? AppColors.lightPeach : AppColors.pastelMint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showSessionDetails(context, security),
                        borderRadius: BorderRadius.circular(16),
                        child: _buildKpiCard(
                          title: 'Active Devices',
                          value: '${security.activeSessions.length}',
                          icon: Icons.devices_rounded,
                          color: AppColors.roseAccent,
                          bgColor: AppColors.softLavender,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Phishing & Scam Scanner Action Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softBlush,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.travel_explore_rounded, color: AppColors.roseAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phishing & Scam Scanner',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          Text(
                            'Analyze suspicious messages, payment links, and fake bank SMS texts.',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showScamScannerSheet(context, security),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roseAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Scan'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Potentially Suspicious Transactions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transaction Anomaly Alerts (${alerts.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.softBlush,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Isolation Forest',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.roseAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (alerts.isEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.shield_outlined, size: 36, color: AppColors.income),
                      const SizedBox(height: 8),
                      Text(
                        'Zero Suspicious Transactions',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      ),
                      Text(
                        'All recent transactions align with your historical spending profile.',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: alerts.map((alert) => _buildAlertCard(context, alert, security)).toList(),
                  ),
                ),

              const SizedBox(height: 18),

              // 5. Security Audit Log Feed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Security Audit Logs (${auditLogs.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'Tamper-Evident',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: auditLogs.take(5).map((log) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: log.severity.containerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(log.icon, color: log.severity.color, size: 20),
                          ),
                          title: Text(
                            log.description,
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          subtitle: Text(
                            '${formatDateTime(log.timestamp)} • ${log.deviceName ?? 'Device'}',
                            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: log.severity.containerColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.severity.name.toUpperCase(),
                              style: TextStyle(
                                color: log.severity.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, FraudAlertModel alert, SecurityProvider security) {
    final isPending = alert.status == FraudAlertStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? alert.riskLevel.color.withOpacity(0.5) : AppColors.divider,
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: alert.riskLevel.color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alert.riskLevel.containerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, color: alert.riskLevel.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            alert.transactionTitle,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: alert.riskLevel.containerColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${alert.riskLevel.displayName} (${alert.riskScore}/100)',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: alert.riskLevel.color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${alert.category} • ${formatCurrency(alert.amount)} • ${formatDate(alert.date)}',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anomaly Indicators:',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                ...alert.reasons.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.roseAccent, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            r,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Action: ${alert.recommendedAction}',
                  style: GoogleFonts.poppins(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Action Buttons with Zero-Overflow Wrap Layout
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending ? AppColors.warning.withOpacity(0.12) : AppColors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.status.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPending ? AppColors.warning : AppColors.textLight,
                  ),
                ),
              ),
              if (isPending)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => security.updateAlertStatus(alert.id, FraudAlertStatus.falsePositive),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.income,
                        side: const BorderSide(color: AppColors.income, width: 1.0),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Safe (False +)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => security.updateAlertStatus(alert.id, FraudAlertStatus.confirmedSuspicious),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Confirm Fraud', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

