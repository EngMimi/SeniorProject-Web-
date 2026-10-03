import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Sends a brain MRI image to the MRI-analysis AI model and reads back its
// prediction.

/// Holds the MRI model's prediction result.
class MriPredictionResult {
  final String prediction;
  final int predictionCode;
  final double probabilityPd;
  final double threshold;
  final String disclaimer;

  const MriPredictionResult({
    required this.prediction,
    required this.predictionCode,
    required this.probabilityPd,
    required this.threshold,
    required this.disclaimer,
  });

  factory MriPredictionResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>;
    final predictedClass = result['predicted_class'] as int;
    final probabilities = result['probabilities'] as Map<String, dynamic>?;
    final probabilityPd =
        (probabilities?['parkinson'] as num?)?.toDouble() ??
        (result['confidence'] as num).toDouble();

    return MriPredictionResult(
      // Converts the model's class number into the same "Parkinson" /
      // "Healthy" wording the other models use.
      prediction: predictedClass == 1 ? 'Parkinson' : 'Healthy',
      predictionCode: predictedClass,
      probabilityPd: probabilityPd,
      threshold: (result['threshold'] as num?)?.toDouble() ?? 0.5,
      disclaimer: result['disclaimer'] as String? ?? '',
    );
  }
}

/// Talks to the brain-MRI AI model hosted on Render. Takes the raw MRI
/// image file.
class MriModelService {
  MriModelService._();
  static final MriModelService instance = MriModelService._();

  static const _baseUrl = 'https://mri-backend-1.onrender.com';

  /// Sends the MRI image to the model and returns its prediction.
  Future<MriPredictionResult> predict({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$_baseUrl/predict/mri');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          // The backend only accepts image/jpeg and image/png — without
          // this, http defaults to application/octet-stream and the
          // backend rejects the upload with a 415 error.
          contentType: _contentTypeFor(filename),
        ),
      );

    late final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
    } on TimeoutException {
      throw Exception(
        'The model took too long to respond. Free-tier hosting can take '
        'up to a minute to wake up — please try again.',
      );
    }
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Model API returned ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return MriPredictionResult.fromJson(data);
  }

  // Picks the MIME type the backend expects (image/jpeg or image/png)
  // based on the file's extension. Falls back to JPEG if the extension
  // is unrecognized.
  MediaType _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    return MediaType('image', 'jpeg');
  }
}
