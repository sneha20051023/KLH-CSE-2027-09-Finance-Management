import 'fraud_alert_model.dart';

/// Represents the analysis result of a text or URL evaluated for financial scams/phishing.
class ScamAnalysisResult {
  final String inputText;
  final bool isSuspicious;
  final FraudRiskLevel riskLevel;
  final int confidenceScore; // 0 to 100
  final List<String> detectedTriggers;
  final String explanation;
  final String recommendation;
  final DateTime analyzedAt;

  const ScamAnalysisResult({
    required this.inputText,
    required this.isSuspicious,
    required this.riskLevel,
    required this.confidenceScore,
    required this.detectedTriggers,
    required this.explanation,
    required this.recommendation,
    required this.analyzedAt,
  });
}

