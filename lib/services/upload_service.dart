// lib/services/upload_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class UploadService {
  // Given a File, upload via presigned flow and get final imageUrl
  static Future<String> uploadFile(File file) async {
    final fileName = p.basename(file.path);
    final presigned = await ApiService.getPresignedUrl(fileName);
    final uploadUrl = presigned['uploadUrl'] as String;
    final fileUrl = presigned['fileUrl'] as String;

    final bytes = await file.readAsBytes();
    final ok = await ApiService.uploadBytesToPresigned(uploadUrl, bytes);
    if (!ok) throw Exception('Failed to upload to presigned url');

    // return final accessible file url (S3 or public url)
    return fileUrl;
  }

  // Alternative: if you want to directly POST multipart to backend, implement here.
}
