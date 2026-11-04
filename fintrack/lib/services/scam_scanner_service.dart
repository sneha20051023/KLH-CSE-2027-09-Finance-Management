import '../models/scam_analysis_model.dart';
import '../models/fraud_alert_model.dart';

/// Text and URL Security Analysis Service for Phishing & Financial Scam Awareness.
///
/// Analyzes user-submitted financial messages, SMS, or URLs for known scam patterns,
/// urgency manipulation, credential harvesting, and suspicious links without opening them.
class ScamScannerService {
  /// Evaluates [input] (text message or link) and returns explainable risk insights.
  ScamAnalysisResult analyze(String input) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) {
      return ScamAnalysisResult(
        inputText: input,
        isSuspicious: false,
        riskLevel: FraudRiskLevel.safe,
        confidenceScore: 0,
        detectedTriggers: [],
        explanation: 'Please enter a message or URL to analyze.',
        recommendation: 'Paste an SMS or email text message suspected of financial fraud.',
        analyzedAt: DateTime.now(),
      );
    }

    final lower = cleanInput.toLowerCase();
    final triggers = <String>[];
    int score = 0;

    // 1. Check for credential harvesting & sensitive requests
    if (lower.contains('otp') || lower.contains('one time password') || lower.contains('one-time password')) {
      score += 35;
      triggers.add('Requests One-Time Password (OTP) — Banks NEVER ask for OTPs');
    }
    if (lower.contains('pin') || lower.contains('mpin') || lower.contains('upi pin') || lower.contains('cvv')) {
      score += 40;
      triggers.add('Requests PIN or CVV credentials');
    }
    if (lower.contains('password') || lower.contains('pass code')) {
      score += 25;
      triggers.add('Requests account password');
    }

    // 2. Urgent / Fear-inducing coercion patterns
    if (lower.contains('block') || lower.contains('suspended') || lower.contains('deactivated') || lower.contains('restricted')) {
      score += 25;
      triggers.add('Fear/Urgency tactic: Claims account, card, or PAN is blocked/suspended');
    }
    if (lower.contains('kyc') && (lower.contains('update') || lower.contains('pending') || lower.contains('expire'))) {
      score += 30;
      triggers.add('Fake KYC expiration alert — classic financial phishing vector');
    }
    if (lower.contains('electricity') && (lower.contains('power will be disconnected') || lower.contains('cut tonight'))) {
      score += 35;
      triggers.add('Electricity bill disconnection scam pattern');
    }
    if (lower.contains('immediately') || lower.contains('urgent') || lower.contains('within 24 hours') || lower.contains('within 2 hours')) {
      score += 20;
      triggers.add('Artificial time urgency forcing hasty decisions');
    }

    // 3. Prize / Lottery / Unrealistic Rewards
    if (lower.contains('congratulations') || lower.contains('won') || lower.contains('lottery') || lower.contains('lucky winner')) {
      score += 30;
      triggers.add('Unsolicited lottery or prize winnings claim');
    }
    if (lower.contains('cashback') && (lower.contains('claim') || lower.contains('scratch card') || lower.contains('reward'))) {
      score += 25;
      triggers.add('Fake cashback/reward claim link');
    }
    if (lower.contains('guaranteed profit') || lower.contains('double your money') || lower.contains('crypto bonus')) {
      score += 35;
      triggers.add('High-yield investment / Ponzi scam indicator');
    }

    // 4. Suspicious URL / Link analysis
    final hasUrl = lower.contains('http://') || lower.contains('https://') || lower.contains('www.') || lower.contains('.com') || lower.contains('.in');
    if (hasUrl) {
      if (lower.contains('http://')) {
        score += 25;
        triggers.add('Insecure HTTP connection (No SSL encryption)');
      }
      if (lower.contains('bit.ly') || lower.contains('tinyurl.com') || lower.contains('is.gd') || lower.contains('t.co')) {
        score += 20;
        triggers.add('Masked URL shortener hiding true destination');
      }
      if (lower.contains('.xyz') || lower.contains('.top') || lower.contains('.apk') || lower.contains('.click') || lower.contains('.ru')) {
        score += 30;
        triggers.add('High-risk top-level domain (.xyz, .top, .apk download)');
      }
      // Check for raw IP address in URL
      final ipRegex = RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b');
      if (ipRegex.hasMatch(cleanInput)) {
        score += 40;
        triggers.add('Direct IP address used instead of legitimate domain name');
      }
    }

    // Determine Risk Level
    final normalizedScore = score.clamp(0, 100);
    FraudRiskLevel riskLevel;
    String explanation;
    String recommendation;

    if (normalizedScore >= 60) {
      riskLevel = normalizedScore >= 80 ? FraudRiskLevel.critical : FraudRiskLevel.high;
      explanation = 'High likelihood of financial phishing or fraudulent impersonation scam. '
          'Multiple malicious triggers detected.';
      recommendation = 'DO NOT click links, DO NOT share OTPs or personal credentials. '
          'Block the sender and report to National Cyber Crime Portal (1930 in India).';
    } else if (normalizedScore >= 30) {
      riskLevel = FraudRiskLevel.medium;
      explanation = 'Message contains suspicious language often associated with aggressive marketing or preliminary scams.';
      recommendation = 'Exercise caution. Verify directly with your bank using their official app or website.';
    } else {
      riskLevel = FraudRiskLevel.safe;
      explanation = 'No obvious financial phishing triggers or known malicious patterns detected.';
      recommendation = 'Appears low risk. Always ensure you are on official HTTPS portals before entering credentials.';
    }

    return ScamAnalysisResult(
      inputText: input,
      isSuspicious: normalizedScore >= 30,
      riskLevel: riskLevel,
      confidenceScore: normalizedScore,
      detectedTriggers: triggers.isEmpty ? ['Standard informational text'] : triggers,
      explanation: explanation,
      recommendation: recommendation,
      analyzedAt: DateTime.now(),
    );
  }
}

