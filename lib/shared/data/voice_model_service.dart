import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Sends pre-computed voice features to the voice-analysis AI model and
// reads back its prediction.

/// The 43 acoustic feature names the voice model expects, in the exact
/// order it requires. Kept the same as the mobile app's list so a CSV
/// that works there also works here.
const List<String> voiceModelFeatureNames = [
  'Jitter_rel', 'Jitter_abs', 'Jitter_RAP', 'Jitter_PPQ',
  'Shim_loc', 'Shim_dB', 'Shim_APQ3', 'Shim_APQ5', 'Shi_APQ11',
  'HNR05', 'HNR15', 'HNR25', 'HNR35', 'HNR38',
  'RPDE', 'DFA', 'PPE', 'GNE',
  'MFCC0', 'MFCC1', 'MFCC2', 'MFCC3', 'MFCC4', 'MFCC5', 'MFCC6',
  'MFCC7', 'MFCC8', 'MFCC9', 'MFCC10', 'MFCC11', 'MFCC12',
  'Delta0', 'Delta1', 'Delta2', 'Delta3', 'Delta4', 'Delta5', 'Delta6',
  'Delta7', 'Delta8', 'Delta9', 'Delta10', 'Delta11', 'Delta12',
];

/// Holds the voice model's prediction result.
class VoicePredictionResult {
  final String prediction;
  final int predictionCode;
  final double probabilityPd;

  const VoicePredictionResult({
    required this.prediction,
    required this.predictionCode,
    required this.probabilityPd,
  });

  factory VoicePredictionResult.fromJson(Map<String, dynamic> json) {
    return VoicePredictionResult(
      prediction: json['prediction'] as String,
      predictionCode: json['prediction_code'] as int,
      probabilityPd: (json['probability_pd'] as num).toDouble(),
    );
  }
}

/// Talks to the voice AI model hosted on Render (same model the Patient
/// Mobile App uses). Expects 43 pre-computed features, not a raw audio
/// file — see [voiceModelFeatureNames] for the exact names and order.
class VoiceModelService {
  VoiceModelService._();
  static final VoiceModelService instance = VoiceModelService._();

  static const _baseUrl = 'https://neuroinsight-voicemodel.onrender.com';

  /// Sends the features to the model and returns its prediction.
  Future<VoicePredictionResult> predict(Map<String, double> features) async {
    final uri = Uri.parse('$_baseUrl/predict');

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'features': features}),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw Exception(
          'The model took too long to respond. Free-tier hosting can take up to a minute to wake up — please try again.');
    }

    if (response.statusCode != 200) {
      throw Exception('Model API returned ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return VoicePredictionResult.fromJson(data);
  }
}
