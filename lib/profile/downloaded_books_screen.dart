import 'package:flutter/material.dart';
import 'dart:io';
import '../models/downloaded_book_model.dart';
import '../services/download_service.dart';
import '../widgets/app_theme.dart';
import '../home/pdf_viewer_screen.dart';

class DownloadedBooksScreen extends StatefulWidget {
  const DownloadedBooksScreen({super.key});

  @override
  State<DownloadedBooksScreen> createState() => _DownloadedBooksScreenState();
}

class _DownloadedBooksScreenState extends State<DownloadedBooksScreen> {
  final DownloadService _downloadService = DownloadService();
  List<DownloadedBook> _downloadedBooks = [];
  int _totalStorageUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloadedBooks();
  }

  Future<void> _loadDownloadedBooks() async {
    final books = _downloadService.getAllDownloadedBooks();
    final storage = await _downloadService.getTotalStorageUsed();
    setState(() {
      _downloadedBooks = books;
      _totalStorageUsed = storage;
    });
  }

  Future<void> _deleteBook(DownloadedBook book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Downloaded Book?'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadService.deleteDownloadedBook(book);
      _loadDownloadedBooks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully')),
        );
      }
    }
  }

  String _formatStorageSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        actions: [
          if (_downloadedBooks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surfaceColor,
                    title: const Text('Storage Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Books: ${_downloadedBooks.length}'),
                        const SizedBox(height: 8),
                        Text('Storage Used: ${_formatStorageSize(_totalStorageUsed)}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _downloadedBooks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No downloaded books yet',
                    style: TextStyle(fontSize: 18, color: Colors.white38),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download books to read them offline',
                    style: TextStyle(color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _downloadedBooks.length,
              itemBuilder: (context, index) {
                return _buildBookCard(_downloadedBooks[index]);
              },
            ),
    );
  }

  Widget _buildBookCard(DownloadedBook book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              filePath: book.localFilePath,
              bookTitle: book.title,
              isOnline: false,
            ),
          ),
        );
      },
      onLongPress: () => _deleteBook(book),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover/Icon
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getFileIcon(book.localFilePath),
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    // Offline badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.offline_pin, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'OFFLINE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.fileSizeFormatted,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String path) {
    final extension = path.toLowerCase().split('.').last;
    if (extension == 'pdf') return Icons.picture_as_pdf;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) return Icons.image;
    return Icons.insert_drive_file;
  }
}
