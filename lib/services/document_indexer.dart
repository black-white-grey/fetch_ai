import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class IndexedDocument {
  final String path;
  final String title;
  final String summary;
  final List<String> keywords;
  final String first500Words;

  IndexedDocument({
    required this.path,
    required this.title,
    required this.summary,
    required this.keywords,
    this.first500Words = '',
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'title': title,
    'summary': summary,
    'keywords': keywords,
    'first500Words': first500Words,
  };

  factory IndexedDocument.fromJson(Map<String, dynamic> json) =>
      IndexedDocument(
        path: json['path'],
        title: json['title'],
        summary: json['summary'],
        keywords: List<String>.from(json['keywords']),
        first500Words: json['first500Words'] ?? '',
      );
}

class DocumentIndexer {
  // Replace with actual API key in a production app or via env vars
  static const String _geminiApiKey = 'YOUR_API_KEY';

  static Future<String> _extractTextFromPdf(String path) async {
    try {
      final File file = File(path);
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      print('Error parsing PDF: $e');
      return '';
    }
  }

  static Future<String> _extractTextFromPptx(String path) async {
    try {
      final File file = File(path);
      final List<int> bytes = await file.readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      StringBuffer extractedText = StringBuffer();

      for (ArchiveFile file in archive) {
        if (file.name.startsWith('ppt/slides/slide') &&
            file.name.endsWith('.xml')) {
          file.decompress();
          final String content = utf8.decode(file.content);
          final document = XmlDocument.parse(content);
          final elements = document.findAllElements('a:t');
          for (var element in elements) {
            extractedText.write('${element.innerText} ');
          }
        }
      }
      return extractedText.toString();
    } catch (e) {
      print('Error parsing PPTX: $e');
      return '';
    }
  }

  static Future<IndexedDocument?> analyzeDocument(String path) async {
    if (!File(path).existsSync()) return null;

    String text = "";
    if (path.toLowerCase().endsWith('.pdf')) {
      text = await _extractTextFromPdf(path);
    } else if (path.toLowerCase().endsWith('.pptx')) {
      text = await _extractTextFromPptx(path);
    } else {
      return null;
    }

    if (text.isEmpty || text.trim().isEmpty) return null;

    final words = text.split(RegExp(r'\s+'));
    final first500Words = words.length > 500 ? words.take(500).join(' ') : text;

    // Send to Gemini
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      final prompt =
          """
Analyze the following academic text and provide a JSON response with exactly two keys:
1. "summary": A dense 3-sentence academic summary of the text.
2. "keywords": A list of 5 exact research keywords or keyphrases.

Here is the text to analyze (may be truncated if very long):
${text.substring(0, text.length > 50000 ? 50000 : text.length)}

Ensure the output is ONLY raw JSON. No markdown blocks, no intro text.
Format Example: {"summary": "...", "keywords": ["...", "..."]}
""";

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        // Clean JSON format in case of markdown block wrappers
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);

        return IndexedDocument(
          path: path,
          title: path.split('/').last.split('\\').last,
          summary: data['summary'] ?? "No summary generated.",
          keywords: List<String>.from(data['keywords'] ?? []),
          first500Words: first500Words,
        );
      }
    } catch (e) {
      print("Gemini Analysis Error: $e");
    }
    return null;
  }
}
