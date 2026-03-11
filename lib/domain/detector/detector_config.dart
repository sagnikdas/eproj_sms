class DetectorConfig {
  final double thresholdMedium;
  final double thresholdHigh;

  final double weightShortUrl;
  final double weightOtp;
  final double weightUrgency;
  final double weightBankKeyword;
  final double weightSuspectSender;
  final double weightInCallOtpBoost;

  final List<String> shortUrlDomains;
  final List<String> urgencyKeywords;
  final List<String> bankKeywords;
  final List<String> suspectSenderPatterns;

  const DetectorConfig({
    required this.thresholdMedium,
    required this.thresholdHigh,
    required this.weightShortUrl,
    required this.weightOtp,
    required this.weightUrgency,
    required this.weightBankKeyword,
    required this.weightSuspectSender,
    required this.weightInCallOtpBoost,
    required this.shortUrlDomains,
    required this.urgencyKeywords,
    required this.bankKeywords,
    required this.suspectSenderPatterns,
  });

  factory DetectorConfig.defaults() {
    return DetectorConfig(
      thresholdMedium: 0.35,
      thresholdHigh: 0.65,
      weightShortUrl: 0.25,
      weightOtp: 0.20,
      weightUrgency: 0.20,
      weightBankKeyword: 0.20,
      weightSuspectSender: 0.10,
      weightInCallOtpBoost: 0.30,
      shortUrlDomains: const [
        'bit.ly',
        'tinyurl.com',
        'goo.gl',
        't.co',
        'ow.ly',
        'is.gd',
        'buff.ly',
        'adf.ly',
        'short.io',
        'rb.gy',
        'cutt.ly',
        'tiny.cc',
        'snip.ly',
      ],
      urgencyKeywords: const [
        'urgent',
        'immediately',
        'suspended',
        'blocked',
        'action required',
        'your account will be',
        'click now',
        'verify now',
        'limited time',
        'expire',
        'final notice',
        'legal action',
        'arrested',
        'penalty',
        'act now',
        'last chance',
        'warning:',
        'alert:',
        'fraud alert',
      ],
      bankKeywords: const [
        'kyc',
        'know your customer',
        'pan card',
        'aadhaar',
        'aadhar',
        'bank account',
        'net banking',
        'credit card',
        'debit card',
        'transaction failed',
        'upi',
        'paytm',
        'gpay',
        'phonepay',
        'neft',
        'imps',
        'ifsc',
        'loan approved',
        'emi',
        'insurance premium',
        'refund initiated',
        'cashback',
      ],
      suspectSenderPatterns: const [
        'secure',
        'alert',
        'verify',
        'support',
        'help-desk',
        'notice',
      ],
    );
  }

  factory DetectorConfig.fromJson(Map<String, dynamic> json) {
    return DetectorConfig(
      thresholdMedium:
          (json['thresholdMedium'] as num?)?.toDouble() ?? 0.35,
      thresholdHigh: (json['thresholdHigh'] as num?)?.toDouble() ?? 0.65,
      weightShortUrl: (json['weightShortUrl'] as num?)?.toDouble() ?? 0.25,
      weightOtp: (json['weightOtp'] as num?)?.toDouble() ?? 0.20,
      weightUrgency: (json['weightUrgency'] as num?)?.toDouble() ?? 0.20,
      weightBankKeyword:
          (json['weightBankKeyword'] as num?)?.toDouble() ?? 0.20,
      weightSuspectSender:
          (json['weightSuspectSender'] as num?)?.toDouble() ?? 0.10,
      weightInCallOtpBoost:
          (json['weightInCallOtpBoost'] as num?)?.toDouble() ?? 0.30,
      shortUrlDomains: (json['shortUrlDomains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'bit.ly',
            'tinyurl.com',
            'goo.gl',
            't.co',
            'ow.ly',
            'is.gd',
            'buff.ly',
            'adf.ly',
            'short.io',
            'rb.gy',
            'cutt.ly',
            'tiny.cc',
            'snip.ly',
          ],
      urgencyKeywords: (json['urgencyKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'urgent',
            'immediately',
            'suspended',
            'blocked',
            'action required',
            'your account will be',
            'click now',
            'verify now',
            'limited time',
            'expire',
            'final notice',
            'legal action',
            'arrested',
            'penalty',
            'act now',
            'last chance',
            'warning:',
            'alert:',
            'fraud alert',
          ],
      bankKeywords: (json['bankKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'kyc',
            'know your customer',
            'pan card',
            'aadhaar',
            'aadhar',
            'bank account',
            'net banking',
            'credit card',
            'debit card',
            'transaction failed',
            'upi',
            'paytm',
            'gpay',
            'phonepay',
            'neft',
            'imps',
            'ifsc',
            'loan approved',
            'emi',
            'insurance premium',
            'refund initiated',
            'cashback',
          ],
      suspectSenderPatterns:
          (json['suspectSenderPatterns'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [
                'secure',
                'alert',
                'verify',
                'support',
                'help-desk',
                'notice',
              ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thresholdMedium': thresholdMedium,
      'thresholdHigh': thresholdHigh,
      'weightShortUrl': weightShortUrl,
      'weightOtp': weightOtp,
      'weightUrgency': weightUrgency,
      'weightBankKeyword': weightBankKeyword,
      'weightSuspectSender': weightSuspectSender,
      'weightInCallOtpBoost': weightInCallOtpBoost,
      'shortUrlDomains': shortUrlDomains,
      'urgencyKeywords': urgencyKeywords,
      'bankKeywords': bankKeywords,
      'suspectSenderPatterns': suspectSenderPatterns,
    };
  }
}

