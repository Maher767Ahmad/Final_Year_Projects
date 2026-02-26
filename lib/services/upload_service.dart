import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadService {
  /// Uploads an image file from web (Chrome) to a custom hosting server using MultipartRequest.
  /// This function uses readAsBytes() instead of file paths since it's for web.
  ///
  /// Parameters:
  /// - imageFile: The XFile from image_picker
  /// - serverUrl: The URL of your custom hosting server endpoint
  /// - fieldName: The field name for the multipart file (default: 'image')
  ///
  /// Returns: A success message or throws an exception on failure.
  ///
  /// CORS Handling:
  /// For this to work, your hosting server must handle CORS (Cross-Origin Resource Sharing).
  /// Add these headers to your server response:
  ///
  /// Access-Control-Allow-Origin: *  (or specify your domain)
  /// Access-Control-Allow-Methods: POST, OPTIONS
  /// Access-Control-Allow-Headers: Content-Type, Authorization
  /// Access-Control-Allow-Credentials: true  (if needed)
  ///
  /// For PHP (if using Apache), add to .htaccess:
  /// Header set Access-Control-Allow-Origin "*"
  /// Header set Access-Control-Allow-Methods "POST, OPTIONS"
  /// Header set Access-Control-Allow-Headers "Content-Type, Authorization"
  ///
  /// Handle preflight OPTIONS request in your server code.
  Future<String> uploadImageToServer(
    XFile imageFile,
    String serverUrl, {
    String fieldName = 'image',
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));

      // Read file as bytes (works on web)
      var bytes = await imageFile.readAsBytes();

      // Create multipart file from bytes
      var multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: imageFile.name,
      );

      // Add file to request
      request.files.add(multipartFile);

      // Send the request
      var response = await request.send();

      // Check response
      if (response.statusCode == 200) {
        // Read response body if needed
        var responseBody = await response.stream.bytesToString();
        return 'Upload successful: $responseBody';
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
