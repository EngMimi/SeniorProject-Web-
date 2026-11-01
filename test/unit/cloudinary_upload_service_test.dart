import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neuroinsight_pd_web/shared/data/cloudinary_upload_service.dart';

void main() {
  group('CloudinaryUploadService.uploadImage', () {
    test('UT-UP01: returns the URL after a successful upload', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1_1/fx91bxgx/image/upload');

        return http.Response(
          '{"secure_url":"https://example.com/test-image.png"}',
          200,
        );
      });

      final service = CloudinaryUploadService.forTesting(client);

      final result = await service.uploadImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'test-image.png',
      );

      expect(result, 'https://example.com/test-image.png');
      client.close();
    });

    test('UT-UP02: throws an error when upload fails', () async {
      final client = MockClient((request) async {
        return http.Response('Upload failed', 400);
      });

      final service = CloudinaryUploadService.forTesting(client);

      await expectLater(
        service.uploadImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'test-image.png',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Image upload failed (400)'),
          ),
        ),
      );

      client.close();
    });

    test('UT-UP03: throws an error when the URL is missing', () async {
      final client = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final service = CloudinaryUploadService.forTesting(client);

      await expectLater(
        service.uploadImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'test-image.png',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Image upload did not return a usable URL.'),
          ),
        ),
      );

      client.close();
    });
  });
}
