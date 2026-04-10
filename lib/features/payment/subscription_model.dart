class Subscription {
  final String id;
  final String userId;
  final String status; // active, inactive, expired
  final int amountPesewas;
  final String? paystackRef;
  final DateTime expiresAt;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.status,
    required this.amountPesewas,
    this.paystackRef,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      amountPesewas: json['amount_pesewas'],
      paystackRef: json['paystack_ref'],
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());
}
