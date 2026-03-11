class DetectorConfig {
  final double thresholdMedium;
  final double thresholdHigh;

  final double weightShortUrl;
  final double weightOtp;
  final double weightUrgency;
  final double weightBankKeyword;
  final double weightSuspectSender;
  final double weightInCallOtpBoost;

  // Additional per-signal weights for specific scam patterns.
  final double weightPaymentRequest;
  final double weightRewardScam;
  final double weightParcelScam;
  final double weightCryptoScam;

  final List<String> shortUrlDomains;
  final List<String> urgencyKeywords;
  final List<String> bankKeywords;
  final List<String> suspectSenderPatterns;
  final List<String> otpKeywords;
  final List<String> paymentRequestKeywords;
  final List<String> rewardScamKeywords;
  final List<String> parcelScamKeywords;
  final List<String> cryptoScamKeywords;

  const DetectorConfig({
    required this.thresholdMedium,
    required this.thresholdHigh,
    required this.weightShortUrl,
    required this.weightOtp,
    required this.weightUrgency,
    required this.weightBankKeyword,
    required this.weightSuspectSender,
    required this.weightInCallOtpBoost,
    required this.weightPaymentRequest,
    required this.weightRewardScam,
    required this.weightParcelScam,
    required this.weightCryptoScam,
    required this.shortUrlDomains,
    required this.urgencyKeywords,
    required this.bankKeywords,
    required this.suspectSenderPatterns,
    required this.otpKeywords,
    required this.paymentRequestKeywords,
    required this.rewardScamKeywords,
    required this.parcelScamKeywords,
    required this.cryptoScamKeywords,
  });

  factory DetectorConfig.defaults() {
    return DetectorConfig(
      thresholdMedium: 0.4,
      thresholdHigh: 0.7,
      weightShortUrl: 0.25,
      weightOtp: 0.25,
      weightUrgency: 0.20,
      weightBankKeyword: 0.20,
      weightSuspectSender: 0.10,
      weightInCallOtpBoost: 0.35,
      weightPaymentRequest: 0.20,
      weightRewardScam: 0.15,
      weightParcelScam: 0.15,
      weightCryptoScam: 0.15,
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
        'rebrand.ly',
        'soo.gd',
        'lnkd.in',
        'bl.ink',
        'shorte.st',
        'clk.im',
        'mcaf.ee',
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
        'court notice',
        'tax penalty',
        'customs issue',
        'delivery failed',
        'payment pending',
        'security alert',
        'unauthorized access',
        'update immediately',
        'account locked',
        'suspicious activity detected',
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
        'statement available',
        'account verification',
        'atm card',
        'bank verification',
        'kyc update',
        'payment declined',
        'transaction alert',
      ],
      suspectSenderPatterns: const [
        'secure',
        'alert',
        'verify',
        'support',
        'help-desk',
        'notice',
        'service',
        'info',
        'update',
        'security',
        'admin',
        'notification',
      ],
      otpKeywords: const [
        'otp',
        'one time password',
        'verification code',
        'security code',
        'login code',
        'authentication code',
        'use this code',
        'do not share this code',
        'password reset code',
      ],
      paymentRequestKeywords: const [
        'pay now',
        'send money',
        'transfer immediately',
        'upi request',
        'approve payment',
        'payment link',
        'complete payment',
        'collect request',
        'request received',
        'upi collect',
        'pending payment',
      ],
      rewardScamKeywords: const [
        'you have won',
        'congratulations winner',
        'lottery',
        'jackpot',
        'claim prize',
        'free reward',
        'gift voucher',
        'lucky draw',
        'winner selected',
        'claim now',
      ],
      parcelScamKeywords: const [
        'parcel delivery',
        'shipment held',
        'delivery failed',
        'customs clearance',
        'track parcel',
        'delivery charge',
        'package pending',
        'courier service',
        'delivery attempt',
        'update delivery address',
      ],
      cryptoScamKeywords: const [
        'bitcoin',
        'crypto investment',
        'double your crypto',
        'ethereum',
        'usdt',
        'crypto wallet',
        'investment opportunity',
        'guaranteed return',
        'trading signal',
        'crypto profit',
      ],
    );
  }

  factory DetectorConfig.fromJson(Map<String, dynamic> json) {
    return DetectorConfig(
      thresholdMedium:
          (json['thresholdMedium'] as num?)?.toDouble() ?? 0.4,
      thresholdHigh: (json['thresholdHigh'] as num?)?.toDouble() ?? 0.7,
      weightShortUrl: (json['weightShortUrl'] as num?)?.toDouble() ?? 0.25,
      weightOtp: (json['weightOtp'] as num?)?.toDouble() ?? 0.25,
      weightUrgency: (json['weightUrgency'] as num?)?.toDouble() ?? 0.20,
      weightBankKeyword:
          (json['weightBankKeyword'] as num?)?.toDouble() ?? 0.20,
      weightSuspectSender:
          (json['weightSuspectSender'] as num?)?.toDouble() ?? 0.10,
      weightInCallOtpBoost:
          (json['weightInCallOtpBoost'] as num?)?.toDouble() ?? 0.35,
      weightPaymentRequest:
          (json['weightPaymentRequest'] as num?)?.toDouble() ?? 0.20,
      weightRewardScam:
          (json['weightRewardScam'] as num?)?.toDouble() ?? 0.15,
      weightParcelScam:
          (json['weightParcelScam'] as num?)?.toDouble() ?? 0.15,
      weightCryptoScam:
          (json['weightCryptoScam'] as num?)?.toDouble() ?? 0.15,
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
            'rebrand.ly',
            'soo.gd',
            'lnkd.in',
            'bl.ink',
            'shorte.st',
            'clk.im',
            'mcaf.ee',
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
            'court notice',
            'tax penalty',
            'customs issue',
            'delivery failed',
            'payment pending',
            'security alert',
            'unauthorized access',
            'update immediately',
            'account locked',
            'suspicious activity detected',
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
            'statement available',
            'account verification',
            'atm card',
            'bank verification',
            'kyc update',
            'payment declined',
            'transaction alert',
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
                'service',
                'info',
                'update',
                'security',
                'admin',
                'notification',
              ],
      otpKeywords: (json['otpKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'otp',
            'one time password',
            'verification code',
            'security code',
            'login code',
            'authentication code',
            'use this code',
            'do not share this code',
            'password reset code',
          ],
      paymentRequestKeywords:
          (json['paymentRequestKeywords'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [
                'pay now',
                'send money',
                'transfer immediately',
                'upi request',
                'approve payment',
                'payment link',
                'complete payment',
                'collect request',
                'request received',
                'upi collect',
                'pending payment',
              ],
      rewardScamKeywords:
          (json['rewardScamKeywords'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [
                'you have won',
                'congratulations winner',
                'lottery',
                'jackpot',
                'claim prize',
                'free reward',
                'gift voucher',
                'lucky draw',
                'winner selected',
                'claim now',
              ],
      parcelScamKeywords:
          (json['parcelScamKeywords'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [
                'parcel delivery',
                'shipment held',
                'delivery failed',
                'customs clearance',
                'track parcel',
                'delivery charge',
                'package pending',
                'courier service',
                'delivery attempt',
                'update delivery address',
              ],
      cryptoScamKeywords:
          (json['cryptoScamKeywords'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [
                'bitcoin',
                'crypto investment',
                'double your crypto',
                'ethereum',
                'usdt',
                'crypto wallet',
                'investment opportunity',
                'guaranteed return',
                'trading signal',
                'crypto profit',
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
      'weightPaymentRequest': weightPaymentRequest,
      'weightRewardScam': weightRewardScam,
      'weightParcelScam': weightParcelScam,
      'weightCryptoScam': weightCryptoScam,
      'shortUrlDomains': shortUrlDomains,
      'urgencyKeywords': urgencyKeywords,
      'bankKeywords': bankKeywords,
      'suspectSenderPatterns': suspectSenderPatterns,
      'otpKeywords': otpKeywords,
      'paymentRequestKeywords': paymentRequestKeywords,
      'rewardScamKeywords': rewardScamKeywords,
      'parcelScamKeywords': parcelScamKeywords,
      'cryptoScamKeywords': cryptoScamKeywords,
    };
  }
}

