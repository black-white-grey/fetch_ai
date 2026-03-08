import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'document_indexer.dart';

class SemanticSearchService {
  static const String _geminiApiKey = 'YOUR_API_KEY';
  static const String _indexFileName = 'semantic_index.json';

  // Lazy-load the index in memory for fast lookup
  List<IndexedDocument> _index = [];
  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    await _loadIndex();
    _isInit = true;
  }

  Future<File> get _indexFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_indexFileName');
  }

  Future<void> _loadIndex() async {
    try {
      final file = await _indexFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        _index = jsonList.map((e) => IndexedDocument.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load semantic index: $e');
    }
  }

  Future<void> saveDocumentToIndex(IndexedDocument doc) async {
    // Check if doc already exists, replace it
    final existingIndex = _index.indexWhere(
      (element) => element.path == doc.path,
    );
    if (existingIndex >= 0) {
      _index[existingIndex] = doc;
    } else {
      _index.add(doc);
    }

    try {
      final file = await _indexFile;
      final jsonList = _index.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      // ignore: avoid_print
      print('Failed to save semantic index: $e');
    }
  }

  /// Takes a raw intent string and compares academic intent against the local index metadata headers.
  Future<List<IndexedDocument>> search(String intent) async {
    if (_index.isEmpty) return [];

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      // We just send the metadata (not raw heavy text) to Gemini to perform the search evaluation
      final documentMetadataList = _index
          .map(
            (doc) => {
              "path": doc.path,
              "title": doc.title,
              "summary": doc.summary,
              "keywords": doc.keywords,
              "first500Words": doc.first500Words,
            },
          )
          .toList();

      final prompt =
          """
You are an Academic Semantic Search Engine. 
A user is searching with the intent: "$intent".

Below is a JSON list of available academic documents, including their summaries, keywords, and the first 500 words of their text:
${jsonEncode(documentMetadataList)}

Your task is to identify which documents best match the user's INTENT.
Crucially, look for conceptual connections. If the user asks for "chemistry", you should identify documents containing words like "Atomic Theory", "Organic", or "Equilibrium" within their summary, keywords, or first500Words, even if the filename is unrelated (e.g., lecture_01.pdf).
Return a JSON array of strings containing ONLY the "path" of the top 3 most relevant documents, ordered by relevance (best match first).
If no documents are relevant, return an empty array [].
DO NOT output markdown blocks. ONLY raw JSON array.
Format Example: ["/path/to/doc1.pdf", "/path/to/doc2.pptx"]
""";

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> matchedPaths = jsonDecode(cleanJson);

        List<IndexedDocument> results = [];
        for (String path in matchedPaths) {
          final matchedDoc = _index.firstWhere(
            (doc) => doc.path == path,
            orElse: () => IndexedDocument(
              path: '',
              title: '',
              summary: '',
              keywords: [],
              first500Words: '',
            ),
          );
          if (matchedDoc.path.isNotEmpty) {
            results.add(matchedDoc);
          }
        }
        if (results.length > 3) {
          results = results.sublist(0, 3);
        }
        return results;
      }
    } catch (e) {
      // ignore: avoid_print
      print("Semantic Search Error: $e");
    }

    // Fallback naive search if Gemini fails
    final fallbackResults = _index.where((doc) {
      final q = intent.toLowerCase();
      return doc.title.toLowerCase().contains(q) ||
          doc.summary.toLowerCase().contains(q) ||
          doc.first500Words.toLowerCase().contains(q) ||
          doc.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();

    return fallbackResults.take(3).toList();
  }

  List<IndexedDocument> getAllDocuments() {
    return _index;
  }
}
