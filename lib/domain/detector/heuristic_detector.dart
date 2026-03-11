import 'package:elder_shield/domain/detector/detector_config.dart';

/// Risk band returned by the detector.
enum RiskBand { low, medium, high }

/// Output of a single detection run.
class DetectionResult {
  final double score;       // 0.0 – 1.0
  final RiskBand band;
  final List<String> reasons; // plain-English explanations for the UI

  const DetectionResult({
    required this.score,
    required this.band,
    required this.reasons,
  });

  @override
  String toString() =>
      'DetectionResult(band: $band, score: ${score.toStringAsFixed(2)}, reasons: $reasons)';
}

/// Deterministic, on-device heuristic detector.
/// All logic lives in pure Dart — no network calls, no ML models.
class HeuristicDetector {
  const HeuristicDetector();

  static DetectorConfig _config = DetectorConfig.defaults();

  static DetectorConfig get config => _config;

  static void updateConfig(DetectorConfig config) {
    _config = config;
  }

  DetectionResult analyze({
    required String sender,
    required String body,
    bool isInCall = false,
  }) {
    final reasons = <String>[];
    double score = 0.0;

    final lowerBody = body.toLowerCase();

    if (_containsShortUrl(lowerBody)) {
      score += _config.weightShortUrl;
      reasons.add('Contains a shortened or suspicious link');
    }

    if (_containsOtpPattern(body)) {
      score += _config.weightOtp;
      reasons.add('Asks for or mentions a one-time code (OTP)');
    }

    if (_containsUrgencyKeywords(lowerBody)) {
      score += _config.weightUrgency;
      reasons.add('Uses urgent or threatening language');
    }

    if (_containsBankKeywords(lowerBody)) {
      score += _config.weightBankKeyword;
      reasons.add('Mentions bank account, KYC, or payment details');
    }

    if (_containsPaymentRequestKeywords(lowerBody)) {
      score += _config.weightPaymentRequest;
      reasons.add('Asks you to send or approve a payment');
    }

    if (_containsRewardScamKeywords(lowerBody)) {
      score += _config.weightRewardScam;
      reasons.add('Looks like a prize or lottery reward scam');
    }

    if (_containsParcelScamKeywords(lowerBody)) {
      score += _config.weightParcelScam;
      reasons.add('Mentions a suspicious parcel or delivery issue');
    }

    if (_containsCryptoScamKeywords(lowerBody)) {
      score += _config.weightCryptoScam;
      reasons.add('Mentions risky crypto investment or guaranteed returns');
    }

    if (_isSuspectSender(sender)) {
      score += _config.weightSuspectSender;
      reasons.add('Sender name looks unusual or suspicious');
    }

    if (isInCall && _containsOtpPattern(body)) {
      score += _config.weightInCallOtpBoost;
      reasons.add('An OTP arrived while you are on a phone call — common scam pattern');
    }

    score = score.clamp(0.0, 1.0);

    final band = score >= _config.thresholdHigh
        ? RiskBand.high
        : score >= _config.thresholdMedium
            ? RiskBand.medium
            : RiskBand.low;

    return DetectionResult(score: score, band: band, reasons: reasons);
  }

  // ── private helpers ────────────────────────────────────────────────────────

  bool _containsShortUrl(String lower) {
    for (final domain in _config.shortUrlDomains) {
      if (lower.contains(domain)) return true;
    }
    // Generic: any http link in SMS body with a very short path
    return RegExp(r'https?://[^\s]{5,30}\b').hasMatch(lower);
  }

  bool _containsOtpPattern(String body) {
    // Matches patterns like "OTP: 123456", "code is 784321", etc.
    final lower = body.toLowerCase();
    for (final kw in _config.otpKeywords) {
      if (lower.contains(kw)) return true;
    }

    final otpRegex = RegExp(
      r'\b(otp|one.?time.?(password|code|pin)|verification code|auth.?code)\b',
      caseSensitive: false,
    );
    final digitCode = RegExp(r'\b\d{4,8}\b');
    return otpRegex.hasMatch(body) || digitCode.hasMatch(body);
  }

  bool _containsUrgencyKeywords(String lower) {
    for (final kw in _config.urgencyKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _containsBankKeywords(String lower) {
    for (final kw in _config.bankKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _containsPaymentRequestKeywords(String lower) {
    for (final kw in _config.paymentRequestKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _containsRewardScamKeywords(String lower) {
    for (final kw in _config.rewardScamKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _containsParcelScamKeywords(String lower) {
    for (final kw in _config.parcelScamKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _containsCryptoScamKeywords(String lower) {
    for (final kw in _config.cryptoScamKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _isSuspectSender(String sender) {
    // Purely numeric sender (not a real business header) but body looks like a scam
    if (RegExp(r'^\+?\d{10,15}$').hasMatch(sender)) return false; // normal phone
    if (sender.length < 3) return true;
    // Common spoofed alpha-sender patterns
    for (final kw in _config.suspectSenderPatterns) {
      if (sender.toLowerCase().contains(kw)) return true;
    }
    return false;
  }
}
