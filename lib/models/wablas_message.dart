class WablasMessage {
  final String phone;
  final String message;

  WablasMessage({
    required this.phone,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'message': message,
    };
  }

  factory WablasMessage.fromJson(Map<String, dynamic> json) {
    return WablasMessage(
      phone: json['phone'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
