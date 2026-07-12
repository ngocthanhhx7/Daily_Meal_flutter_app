enum PremiumPlanId {
  month('premium_month'),
  quarter('premium_quarter'),
  half('premium_half');

  const PremiumPlanId(this.wireValue);
  final String wireValue;
  static PremiumPlanId fromWire(String value) =>
      values.firstWhere((item) => item.wireValue == value);
}

enum PaymentStatus {
  pending('PENDING'),
  paid('PAID'),
  processing('PROCESSING'),
  cancelled('CANCELLED'),
  expired('EXPIRED');

  const PaymentStatus(this.wireValue);
  final String wireValue;
  static PaymentStatus fromWire(String value) =>
      values.firstWhere((item) => item.wireValue == value);
}

class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.name,
    required this.displayPrice,
    required this.amount,
    required this.durationMonths,
  });
  factory PremiumPlan.fromJson(Map<String, dynamic> json) => PremiumPlan(
    id: PremiumPlanId.fromWire(json['id'] as String),
    name: json['name'] as String,
    displayPrice: json['displayPrice'] as String,
    amount: (json['amount'] as num).toInt(),
    durationMonths: (json['durationMonths'] as num).toInt(),
  );
  final PremiumPlanId id;
  final String name;
  final String displayPrice;
  final int amount;
  final int durationMonths;
}

class PayosPayment {
  const PayosPayment({
    required this.id,
    required this.planId,
    required this.orderCode,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentLinkId,
    this.checkoutUrl,
    this.qrCode,
  });
  factory PayosPayment.fromJson(Map<String, dynamic> json) => PayosPayment(
    id: json['id'] as String,
    planId: PremiumPlanId.fromWire(json['planId'] as String),
    orderCode: (json['orderCode'] as num).toInt(),
    amount: (json['amount'] as num).toInt(),
    currency: json['currency'] as String,
    status: PaymentStatus.fromWire(json['status'] as String),
    paymentLinkId: json['paymentLinkId'] as String?,
    checkoutUrl: json['checkoutUrl'] as String?,
    qrCode: json['qrCode'] as String?,
  );
  final String id;
  final PremiumPlanId planId;
  final int orderCode;
  final int amount;
  final String currency;
  final PaymentStatus status;
  final String? paymentLinkId;
  final String? checkoutUrl;
  final String? qrCode;
  bool get terminal =>
      status == PaymentStatus.paid ||
      status == PaymentStatus.cancelled ||
      status == PaymentStatus.expired;
}
