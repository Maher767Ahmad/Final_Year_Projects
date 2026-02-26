class BookRequestModel {
  final int id;
  final String studentId;
  final String studentName;
  final String department;
  final String bookName;
  final String status; // 'pending' | 'fulfilled' | 'rejected'
  final DateTime requestedDate;
  final String? fulfilledBy;
  final DateTime? fulfilledDate;

  BookRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.bookName,
    required this.status,
    required this.requestedDate,
    this.fulfilledBy,
    this.fulfilledDate,
  });

  factory BookRequestModel.fromJson(Map<String, dynamic> json) {
    return BookRequestModel(
      id: int.parse(json['id'].toString()),
      studentId: json['student_id'].toString(),
      studentName: json['student_name'] ?? 'Unknown Student',
      department: json['department'],
      bookName: json['book_name'],
      status: json['status'],
      requestedDate: DateTime.parse(json['requested_date']),
      fulfilledBy: json['fulfilled_by_name']?.toString() ?? json['fulfilled_by']?.toString(),
      fulfilledDate: json['fulfilled_date'] != null
          ? DateTime.parse(json['fulfilled_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'department': department,
      'book_name': bookName,
      'status': status,
      'requested_date': requestedDate.toIso8601String(),
      'fulfilled_by': fulfilledBy,
      'fulfilled_date': fulfilledDate?.toIso8601String(),
    };
  }
}
