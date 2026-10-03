import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

// Sends a spiral-drawing image to the drawing-analysis AI model and reads
// back its prediction.

/// Holds the drawing model's prediction result.
class DrawingPredictionResult {
  final String prediction;
  final double parkinsonProbability;
  final double threshold;

  const DrawingPredictionResult({
    required this.prediction,
    required this.parkinsonProbability,
    required this.threshold,
  });

  factory DrawingPredictionResult.fromJson(Map<String, dynamic> json) {
    return DrawingPredictionResult(
      prediction: json['prediction'] as String,
      parkinsonProbability: (json['parkinson_probability'] as num).toDouble(),
      threshold: (json['threshold'] as num).toDouble(),
    );
  }

  /// 1 if the model predicted Parkinson's, 0 otherwise — same convention
  /// as the voice model, so both display the same way.
  int get predictionCode =>
      prediction.toLowerCase().contains('parkinson') ? 1 : 0;
}

/// Talks to the spiral-drawing AI model hosted on Render. Unlike the voice
/// model, it takes the raw image file, not pre-computed features.
class DrawingModelService {
  DrawingModelService._();
  static final DrawingModelService instance = DrawingModelService._();

  static const _baseUrl = 'https://drawing-backend-iz1o.onrender.com';

  /// Sends the drawing image to the model and returns its prediction.
  Future<DrawingPredictionResult> predict({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
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
    return DrawingPredictionResult.fromJson(data);
  }
}
