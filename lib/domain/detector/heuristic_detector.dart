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
/// Thresholds and keyword lists live in [DetectorConstants].
class HeuristicDetector {
  const HeuristicDetector();

  DetectionResult analyze({
    required String sender,
    required String body,
    bool isInCall = false,
  }) {
    final reasons = <String>[];
    double score = 0.0;

    final lowerBody = body.toLowerCase();

    // — Suspicious URL / shortener —
    if (_containsShortUrl(lowerBody)) {
      score += DetectorConstants.weightShortUrl;
      reasons.add('Contains a shortened or suspicious link');
    }

    // — OTP / verification code request —
    if (_containsOtpPattern(body)) {
      score += DetectorConstants.weightOtp;
      reasons.add('Asks for or mentions a one-time code (OTP)');
    }

    // — Urgency / fear keywords —
    if (_containsUrgencyKeywords(lowerBody)) {
      score += DetectorConstants.weightUrgency;
      reasons.add('Uses urgent or threatening language');
    }

    // — Bank / KYC / payment keywords —
    if (_containsBankKeywords(lowerBody)) {
      score += DetectorConstants.weightBankKeyword;
      reasons.add('Mentions bank account, KYC, or payment details');
    }

    // — Sender anomaly (numeric-only / alpha-numeric spoofed headers) —
    if (_isSuspectSender(sender)) {
      score += DetectorConstants.weightSuspectSender;
      reasons.add('Sender name looks unusual or suspicious');
    }

    // — OTP while in-call boost (high social-engineering risk) —
    if (isInCall && _containsOtpPattern(body)) {
      score += DetectorConstants.weightInCallOtpBoost;
      reasons.add('An OTP arrived while you are on a phone call — common scam pattern');
    }

    score = score.clamp(0.0, 1.0);

    final band = score >= DetectorConstants.thresholdHigh
        ? RiskBand.high
        : score >= DetectorConstants.thresholdMedium
            ? RiskBand.medium
            : RiskBand.low;

    return DetectionResult(score: score, band: band, reasons: reasons);
  }

  // ── private helpers ────────────────────────────────────────────────────────

  bool _containsShortUrl(String lower) {
    for (final domain in DetectorConstants.shortUrlDomains) {
      if (lower.contains(domain)) return true;
    }
    // Generic: any http link in SMS body with a very short path
    return RegExp(r'https?://[^\s]{5,30}\b').hasMatch(lower);
  }

  bool _containsOtpPattern(String body) {
    // Matches patterns like "OTP: 123456", "code is 784321", etc.
    final otpRegex = RegExp(
      r'\b(otp|one.?time.?(password|code|pin)|verification code|auth.?code)\b',
      caseSensitive: false,
    );
    final digitCode = RegExp(r'\b\d{4,8}\b');
    return otpRegex.hasMatch(body) || digitCode.hasMatch(body);
  }

  bool _containsUrgencyKeywords(String lower) {
    for (final kw in DetectorConstants.urgencyKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _containsBankKeywords(String lower) {
    for (final kw in DetectorConstants.bankKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  bool _isSuspectSender(String sender) {
    // Purely numeric sender (not a real business header) but body looks like a scam
    if (RegExp(r'^\+?\d{10,15}$').hasMatch(sender)) return false; // normal phone
    if (sender.length < 3) return true;
    // Common spoofed alpha-sender patterns
    for (final kw in DetectorConstants.suspectSenderPatterns) {
      if (sender.toLowerCase().contains(kw)) return true;
    }
    return false;
  }
}

/// All tunable constants in one place.
/// Sensitivity mode (Block 5) will multiply these weights at runtime.
class DetectorConstants {
  DetectorConstants._();

  // Score thresholds
  static const double thresholdMedium = 0.35;
  static const double thresholdHigh = 0.65;

  // Per-signal weights (sum to ≤ 1.0 before in-call boost)
  static const double weightShortUrl = 0.25;
  static const double weightOtp = 0.20;
  static const double weightUrgency = 0.20;
  static const double weightBankKeyword = 0.20;
  static const double weightSuspectSender = 0.10;
  static const double weightInCallOtpBoost = 0.30; // added on top

  // URL shorteners and suspicious domains
  static const List<String> shortUrlDomains = [
    'bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'ow.ly',
    'is.gd', 'buff.ly', 'adf.ly', 'short.io', 'rb.gy',
    'cutt.ly', 'tiny.cc', 'snip.ly',
  ];

  // Urgency / fear phrases
  static const List<String> urgencyKeywords = [
    'urgent', 'immediately', 'suspended', 'blocked', 'action required',
    'your account will be', 'click now', 'verify now', 'limited time',
    'expire', 'final notice', 'legal action', 'arrested', 'penalty',
    'act now', 'last chance', 'warning:', 'alert:', 'fraud alert',
  ];

  // Bank / KYC / payment bait
  static const List<String> bankKeywords = [
    'kyc', 'know your customer', 'pan card', 'aadhaar', 'aadhar',
    'bank account', 'net banking', 'credit card', 'debit card',
    'transaction failed', 'upi', 'paytm', 'gpay', 'phonepay',
    'neft', 'imps', 'ifsc', 'loan approved', 'emi',
    'insurance premium', 'refund initiated', 'cashback',
  ];

  // Suspicious sender header fragments (alpha senders only)
  static const List<String> suspectSenderPatterns = [
    'secure', 'alert', 'verify', 'support', 'help-desk', 'notice',
  ];
}
