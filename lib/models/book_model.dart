class BookModel {
  final int id;
  final String title;
  final String author;
  final String department;
  final String subject;
  final String fileUrl;
  final String? coverImage;
  final String accessType; // 'read' or 'download'
  final String uploadedBy;
  final DateTime createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.department,
    required this.subject,
    required this.fileUrl,
    this.coverImage,
    required this.accessType,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    String fileUrl = json['file_url'] ?? '';
    String? coverImage = json['cover_image'];

    // Ensure absolute URLs and handle local development URLs (localhost, 10.0.2.2, etc.)
    const String liveBaseUrl = 'https://buildshere.cc/BACKEND';
    
    // Function to normalize URLs
    String normalizeUrl(String url) {
      if (url.isEmpty) return url;
      
      // If relative path
      if (!url.startsWith('http')) {
        return '$liveBaseUrl/${url.startsWith('/') ? url.substring(1) : url}';
      }
      
      // If localhost or local IP (happens if uploaded from local dev server)
      if (url.contains('localhost') || url.contains('127.0.0.1') || url.contains('10.0.2.2')) {
        // Extract the path after the host
        try {
          final uri = Uri.parse(url);
          final path = uri.path;
          if (path.toLowerCase().contains('/backend/')) {
            // Replace any case of /backend/ with the correct live domain
            final correctPath = path.replaceFirst(RegExp(r'/backend/', caseSensitive: false), '/BACKEND/');
            return 'https://buildshere.cc$correctPath';
          }
          return '$liveBaseUrl/${path.startsWith('/') ? path.substring(1) : path}';
        } catch (e) {
          return url;
        }
      }
      
      return url;
    }

    fileUrl = normalizeUrl(fileUrl);
    if (coverImage != null) {
      coverImage = normalizeUrl(coverImage);
    }

    return BookModel(
      id: int.parse(json['id'].toString()),
      title: json['title'],
      author: json['author'],
      department: json['department'],
      subject: json['subject'],
      fileUrl: fileUrl,
      coverImage: coverImage,
      accessType: json['access_type'],
      uploadedBy: json['uploaded_by'].toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'department': department,
      'subject': subject,
      'file_url': fileUrl,
      'cover_image': coverImage,
      'access_type': accessType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
