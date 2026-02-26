import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/book_model.dart';
import '../models/downloaded_book_model.dart';
import '../services/download_service.dart';
import '../widgets/app_theme.dart';
import 'pdf_viewer_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final DownloadService _downloadService = DownloadService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isOfflineAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkOfflineAvailability();
  }

  void _checkOfflineAvailability() {
    setState(() {
      _isOfflineAvailable = _downloadService.isBookDownloaded(widget.book.id);
    });
  }

  Future<void> _handleAction() async {
    if (_isOfflineAvailable) {
      _openOfflineBook();
    } else {
      _showReadOptions();
    }
  }

  void _showReadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reading Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Both options stay within the app.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility, color: AppTheme.primaryColor),
              title: const Text('Read Online (In-App)'),
              subtitle: const Text('Requires internet connection'),
              onTap: () {
                Navigator.pop(context);
                _openOnlineBook();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline, color: AppTheme.primaryColor),
              title: const Text('Save for Offline (In-App)'),
              subtitle: const Text('Download to "My Downloads"'),
              onTap: () {
                Navigator.pop(context);
                _downloadForOffline();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openOnlineBook() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          url: widget.book.fileUrl,
          bookTitle: widget.book.title,
          isOnline: true,
        ),
      ),
    );
  }

  void _openOfflineBook() {
    final downloadedBook = _downloadService.getDownloadedBook(widget.book.id);
    if (downloadedBook != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            filePath: downloadedBook.localFilePath,
            bookTitle: downloadedBook.title,
            isOnline: false,
          ),
        ),
      );
    }
  }

  Future<void> _downloadForOffline() async {
    try {
      // NOTE: We are using getApplicationDocumentsDirectory() inside DownloadService,
      // which is app-private storage and DOES NOT require storage permissions.
      // This fix removes the "Storage permission denied" error on Android.

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      await _downloadService.downloadBook(
        book: widget.book,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      setState(() {
        _isDownloading = false;
        _isOfflineAvailable = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book ready for in-app reading!')),
        );
        // Automatically open the book after download if requested
        _openOfflineBook();
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load book: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Book Cover
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.book.coverImage != null)
                    CachedNetworkImage(
                      imageUrl: widget.book.coverImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.white10,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white10,
                        child: const Icon(Icons.book, size: 100),
                      ),
                    )
                  else
                    Container(
                      color: Colors.white10,
                      child: const Icon(Icons.book, size: 100, color: Colors.white24),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundColor.withOpacity(0.7),
                          AppTheme.backgroundColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Book Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.book.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    'by ${widget.book.author}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metadata Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.domain,
                          'Department',
                          widget.book.department,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.subject,
                          'Subject',
                          widget.book.subject,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.calendar_today,
                          'Uploaded',
                          _formatDate(widget.book.createdAt),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          widget.book.accessType == 'read'
                              ? Icons.visibility
                              : Icons.download,
                          'Access',
                          widget.book.accessType.toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Download/Read Button
                  if (_isDownloading)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: Colors.white10,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saving for offline... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _handleAction,
                        icon: const Icon(Icons.menu_book),
                        label: Text(
                          _isOfflineAvailable
                              ? 'Open Offline'
                              : 'Read Options',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOfflineAvailable 
                              ? Colors.green.shade700 
                              : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
