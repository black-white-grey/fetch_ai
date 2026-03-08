import 'package:flutter_test/flutter_test.dart';
import 'package:fetch_ai/services/document_indexer.dart';
import 'package:fetch_ai/services/semantic_search_service.dart';

void main() {
  group('Academic Intelligence Core Tests', () {
    test('IndexedDocument serialization check', () {
      final doc = IndexedDocument(
        path: '/storage/emulated/0/test.pdf',
        title: 'test.pdf',
        summary: 'This is a mocked academic summary.',
        keywords: ['AI', 'Development', 'Education'],
        first500Words: 'These are the first five hundred words of the text.',
      );

      final json = doc.toJson();
      expect(json['title'], 'test.pdf');
      expect(json['keywords'].length, 3);
      expect(json['first500Words'], contains('hundred words'));

      final decodedDoc = IndexedDocument.fromJson(json);
      expect(decodedDoc.path, '/storage/emulated/0/test.pdf');
      expect(decodedDoc.first500Words, isNotEmpty);
    });

    test('SemanticSearchService instantiation', () {
      final service = SemanticSearchService();
      expect(service.getAllDocuments(), isEmpty);
    });

    // NOTE: Full AI tests require API mocking or integration test environments.
    // The Gemini indexing logic should be manually verified using the Android emulator
    // by attaching real PDF/PPTX files.
  });
}
