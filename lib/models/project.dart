class Project {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String type;
  final String status;
  final String budget;
  final String adminNote;
  final String createdAt;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String suggestedPrice;
  final String deadline;
  final String rejectReason;
  final String customerResponse;
  final String customerNote;

  Project({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.budget,
    required this.adminNote,
    required this.createdAt,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.suggestedPrice = '',
    this.deadline = '',
    this.rejectReason = '',
    this.customerResponse = '',
    this.customerNote = '',
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      budget: json['budget'] ?? '',
      adminNote: json['admin_note'] ?? '',
      createdAt: json['created_at'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      suggestedPrice: json['suggested_price'] ?? '',
      deadline: json['deadline'] ?? '',
      rejectReason: json['reject_reason'] ?? '',
      customerResponse: json['customer_response'] ?? '',
      customerNote: json['customer_note'] ?? '',
    );
  }

  int get statusColor {
    switch (status) {
      case 'active':
        return 0xFFFFA500;
      case 'done':
        return 0xFF4CAF50;
      case 'ready':
        return 0xFF2196F3;
      case 'rejected':
        return 0xFFF44336;
      case 'suggested':
        return 0xFF9C27B0;
      case 'cancelled':
        return 0xFF607D8B;
      default:
        return 0xFF9E9E9E;
    }
  }

  String get statusText {
    switch (status) {
      case 'active':
        return 'در حال انجام';
      case 'done':
        return 'تحویل شده';
      case 'ready':
        return 'آماده تحویل';
      case 'rejected':
        return 'رد شده';
      case 'suggested':
        return 'پیشنهاد اصلاحی';
      case 'cancelled':
        return 'لغو شده';
      case 'pending':
        return 'در انتظار تایید';
      default:
        return status;
    }
  }
}