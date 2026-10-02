import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Uploads a file to Cloudinary's free tier using an unsigned upload
/// preset — no API secret is ever used client-side, which is what makes
/// this safe to call directly from the browser.
///
/// Used by both the doctor's spiral-drawing upload and the radiologist's
/// MRI scan upload: neither model exists yet, so this just gets the image
/// file somewhere reachable (a `fileUrl`) for the test record.
class CloudinaryUploadService {
  CloudinaryUploadService._();

  static final CloudinaryUploadService instance = CloudinaryUploadService._();

  // From the NeuroInsight-PD Cloudinary account's Dashboard (Cloud name)
  // and Settings → Upload → Upload presets (an unsigned preset).
  static const String _cloudName = 'fx91bxgx';
  static const String _uploadPreset = 'storge';

  /// Uploads [bytes] (named [filename], for Cloudinary's own record) and
  /// returns its public HTTPS URL. Throws an [Exception] with a short
  /// user-facing message on failure.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Image upload failed (${response.statusCode}). Please try again.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final url = body['secure_url'] as String?;
    if (url == null) {
      throw Exception('Image upload did not return a usable URL.');
    }
    return url;
  }
}
