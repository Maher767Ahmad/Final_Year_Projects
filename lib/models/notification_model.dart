class AppNotification {
  final int id;
  final String userId;
  final String type; // 'approval' | 'book_request' | 'book_upload'
  final String message;
  final int? relatedId;
  final bool readStatus;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.relatedId,
    required this.readStatus,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: int.parse(json['id'].toString()),
      userId: json['user_id'].toString(),
      type: json['type'],
      message: json['message'],
      relatedId: json['related_id'] != null 
          ? int.tryParse(json['related_id'].toString()) 
          : null,
      readStatus: json['read_status'].toString() == '1' || json['read_status'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'related_id': relatedId,
      'read_status': readStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
