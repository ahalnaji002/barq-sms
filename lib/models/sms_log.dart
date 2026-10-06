enum SmsLogStatus { pending, sent, delivered, failed }

class SmsLog {
  final int? id;
  final String beneficiaryName;
  final String phoneNumber;
  final String message;
  final DateTime sentAt;
  final SmsLogStatus status;
  final DateTime? deliveredAt;
  final String? errorMessage;

  const SmsLog({
    this.id,
    required this.beneficiaryName,
    required this.phoneNumber,
    required this.message,
    required this.sentAt,
    this.status = SmsLogStatus.pending,
    this.deliveredAt,
    this.errorMessage,
  });

  SmsLog copyWith({
    int? id,
    String? beneficiaryName,
    String? phoneNumber,
    String? message,
    DateTime? sentAt,
    SmsLogStatus? status,
    DateTime? deliveredAt,
    String? errorMessage,
  }) {
    return SmsLog(
      id: id ?? this.id,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'beneficiary_name': beneficiaryName,
      'phone_number': phoneNumber,
      'message': message,
      'sent_at': sentAt.toIso8601String(),
      'is_success': isSuccess ? 1 : 0,
      'status': status.name,
      'delivered_at': deliveredAt?.toIso8601String(),
      'error_message': errorMessage,
    };
  }

  factory SmsLog.fromMap(Map<String, dynamic> map) {
    return SmsLog(
      id: map['id'] as int?,
      beneficiaryName: map['beneficiary_name'] as String,
      phoneNumber: map['phone_number'] as String,
      message: map['message'] as String,
      sentAt: DateTime.parse(map['sent_at'] as String),
      status: _statusFromMap(map),
      deliveredAt: map['delivered_at'] == null
          ? null
          : DateTime.tryParse(map['delivered_at'].toString()),
      errorMessage: map['error_message'] as String?,
    );
  }

  bool get isSuccess =>
      status == SmsLogStatus.sent || status == SmsLogStatus.delivered;

  static SmsLogStatus _statusFromMap(Map<String, dynamic> map) {
    final value = map['status']?.toString();
    return SmsLogStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => (map['is_success'] as int? ?? 0) == 1
          ? SmsLogStatus.sent
          : SmsLogStatus.failed,
    );
  }
}
