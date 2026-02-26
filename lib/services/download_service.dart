import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../models/downloaded_book_model.dart';
import '../models/book_model.dart';

class DownloadService {
  static const String _boxName = 'downloaded_books';
  
  // Get Hive box
  Box<DownloadedBook> get _box => Hive.box<DownloadedBook>(_boxName);
  
  // Check if running on web
  bool get _isWeb => kIsWeb;

  // Check if book is already downloaded
  bool isBookDownloaded(int bookId) {
    return _box.values.any((book) => book.bookId == bookId);
  }

  // Get downloaded book by ID
  DownloadedBook? getDownloadedBook(int bookId) {
    try {
      return _box.values.firstWhere((book) => book.bookId == bookId);
    } catch (e) {
      return null;
    }
  }

  // Get all downloaded books
  List<DownloadedBook> getAllDownloadedBooks() {
    return _box.values.toList();
  }

  // Download and save book
  Future<DownloadedBook> downloadBook({
    required BookModel book,
    required Function(double) onProgress,
  }) async {
    // Web platform doesn't support file downloads to local storage yet
    if (_isWeb) {
      throw Exception('Download functionality is not available on web. Please use the mobile app.');
    }
    
    // Get app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${directory.path}/books');
    
    // Create books directory if it doesn't exist
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    // Extract extension from URL, fallback to .pdf if none found
    String extension = p.extension(book.fileUrl);
    if (extension.isEmpty) {
      extension = '.pdf';
    }

    // Create filename from book title and ID
    final fileName = '${book.id}_${book.title.replaceAll(RegExp(r'[^\w\s-]'), '')}$extension';
    final filePath = '${booksDir.path}/$fileName';

    // Download file with validation
    final dio = Dio();
    
    // 1. Get headers first to check content type
    final headResponse = await dio.head(book.fileUrl);
    final contentType = headResponse.headers.value('content-type');
    
    if (contentType != null && contentType.contains('text/html')) {
      throw Exception('Server returned an error page (HTML) instead of a PDF. Please check the file link.');
    }

    // 2. Perform actual download
    await dio.download(
      book.fileUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
    );

    // Get file size and validate
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File download failed: File does not exist');
    }
    
    final fileSize = await file.length();
    if (fileSize < 1024) { // Less than 1KB is likely not a valid book
      debugPrint('Warning: Downloaded file is very small ($fileSize bytes). Possible error page.');
    }

    // Create DownloadedBook object
    final downloadedBook = DownloadedBook(
      bookId: book.id,
      title: book.title,
      author: book.author,
      department: book.department,
      subject: book.subject,
      localFilePath: filePath,
      downloadDate: DateTime.now(),
      fileSizeBytes: fileSize,
      accessType: book.accessType,
    );

    // Save to Hive
    await _box.add(downloadedBook);

    return downloadedBook;
  }

  // Delete downloaded book
  Future<void> deleteDownloadedBook(DownloadedBook book) async {
    if (!kIsWeb) {
      // Delete file from storage
      final file = File(book.localFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Remove from Hive
    await book.delete();
  }

  // Get total storage used
  Future<int> getTotalStorageUsed() async {
    if (kIsWeb) return 0;
    
    int total = 0;
    for (var book in _box.values) {
      final file = File(book.localFilePath);
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    for (var book in _box.values.toList()) {
      await deleteDownloadedBook(book);
    }
  }
}
