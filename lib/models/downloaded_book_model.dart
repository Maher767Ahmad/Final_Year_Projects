import 'package:hive/hive.dart';

part 'downloaded_book_model.g.dart';

@HiveType(typeId: 0)
class DownloadedBook extends HiveObject {
  @HiveField(0)
  final int bookId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String department;

  @HiveField(4)
  final String subject;

  @HiveField(5)
  final String localFilePath;

  @HiveField(6)
  final DateTime downloadDate;

  @HiveField(7)
  final int fileSizeBytes;

  @HiveField(8)
  final String accessType;

  DownloadedBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.department,
    required this.subject,
    required this.localFilePath,
    required this.downloadDate,
    required this.fileSizeBytes,
    required this.accessType,
  });

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
