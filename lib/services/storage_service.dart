import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'api_service.dart';
import 'dart:convert';

class StorageService {
  
  Future<String> uploadFile(dynamic file, String folder) async {
    final String uploadUrl = '${ApiService.baseUrl}?endpoint=/upload';
    
    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else if (file is XFile) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else if (file is PlatformFile) {
         if (file.path != null) {
            request.files.add(await http.MultipartFile.fromPath('file', file.path!));
         } else if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
         }
      } else {
        throw Exception('Unsupported file type');
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // debugPrint('Upload Response: ${response.body}');
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['url'];
      } else {
        throw Exception('Upload failed: ${response.statusCode} - Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<String> uploadIdCard(dynamic file, String userId) async {
    return await uploadFile(file, 'id_cards/$userId');
  }

  Future<String> uploadBook(dynamic file, String department) async {
    return await uploadFile(file, 'books/$department');
  }

  Future<String> uploadProfilePicture(dynamic file, String userId) async {
    return await uploadFile(file, 'profiles/$userId');
  }
}
