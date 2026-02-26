import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_io/io.dart';
import '../widgets/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? filePath;
  final String? url;
  final String bookTitle;
  final bool isOnline;

  const PdfViewerScreen({
    Key? key,
    this.filePath,
    this.url,
    required this.bookTitle,
    this.isOnline = false,
  }) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOnline && widget.url != null) {
      final extension = widget.url!.toLowerCase().split('?').first.split('.').last;
      if (!['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        final googleDocsUrl = 'https://docs.google.com/viewer?url=${widget.url}&embedded=true';
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                if (mounted) setState(() => _isWebViewLoading = false);
              },
              onWebResourceError: (error) {
                if (mounted) setState(() => _hasError = true);
              },
            ),
          )
          ..loadRequest(Uri.parse(googleDocsUrl));
      }
    }
  }

  Future<void> _openExternalApp(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app found to open this file.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? displayPath = widget.filePath ?? widget.url;
    if (displayPath == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.bookTitle)),
        body: const Center(child: Text('No file or URL provided')),
      );
    }

    final queryFreePath = displayPath.split('?').first;
    final extension = queryFreePath.toLowerCase().split('.').last;
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
    final isPdf = extension == 'pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bookTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showFileInfo(context);
            },
          ),
        ],
      ),
      body: widget.isOnline
          ? _buildOnlineViewer(context, isImage, isPdf)
          : (widget.filePath != null && File(widget.filePath!).existsSync()
              ? _buildLocalViewer(context, isImage, isPdf)
              : _buildFileNotFound()),
    );
  }

  Widget _buildOnlineViewer(BuildContext context, bool isImage, bool isPdf) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Connection Problem', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Could not load the online viewer.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _hasError = false;
                _isWebViewLoading = true;
                _webViewController.reload();
              }),
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }

    if (isPdf) {
      return SfPdfViewer.network(
        widget.url!,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
      );
    } else if (isImage) {
      return Center(
        child: InteractiveViewer(
          child: Image.network(
            widget.url!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 50, color: Colors.red),
          ),
        ),
      );
    } else {
      return Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isWebViewLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        ],
      );
    }
  }

  Widget _buildLocalViewer(BuildContext context, bool isImage, bool isPdf) {
    final file = File(widget.filePath!);
    final ext = file.path.split('.').last.toLowerCase();
    final isDoc = ['doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'].contains(ext);

    if (isPdf) {
      return SfPdfViewer.file(
        file,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        },
      );
    } else if (isImage) {
      return Center(
        child: InteractiveViewer(child: Image.file(file, fit: BoxFit.contain)),
      );
    } else if (isDoc || ext == 'docx' || ext == 'doc') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 80,
                color: Colors.white24,
              ),
              const SizedBox(height: 24),
              const Text(
                'Document Reader',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'This document ($ext) is ready to be opened in your preferred reading app for the best experience.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _openExternalApp(file.path),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chrome_reader_mode_outlined),
                label: const Text('Open Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 80,
                color: Colors.white24,
              ),
              const SizedBox(height: 24),
              const Text(
                'Unsupported Offline Format',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'The format ".$ext" cannot be viewed offline inside the app yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tip: For the best offline experience, please upload books in PDF format.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildFileNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('File not found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'The file may have been deleted or moved',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  void _showFileInfo(BuildContext context) {
    final String? path = widget.filePath ?? widget.url;
    if (path == null) return;

    final isLocal = widget.filePath != null && File(widget.filePath!).existsSync();
    final fileSize = isLocal ? File(widget.filePath!).lengthSync() : 0;
    
    String fileSizeFormatted = 'N/A (Remote)';
    if (isLocal) {
      if (fileSize < 1024 * 1024) {
        fileSizeFormatted = '${(fileSize / 1024).toStringAsFixed(1)} KB';
      } else {
        fileSizeFormatted = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('File Type', isLocal ? path.split('.').last.toUpperCase() : 'Remote'),
            const SizedBox(height: 8),
            _buildInfoRow('Storage', isLocal ? 'Offline' : 'Online'),
            const SizedBox(height: 8),
            _buildInfoRow('Size', fileSizeFormatted),
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
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
      ],
    );
  }
}
