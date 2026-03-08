import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/semantic_search_service.dart';
import '../services/document_indexer.dart';
import '../services/file_traversal_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final SemanticSearchService _searchService = SemanticSearchService();
  List<IndexedDocument> _documents = [];
  bool _isScanning = false;
  String _scanStatus = "Idle";
  String? _vaultPath;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadIndex();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vaultPath = prefs.getString('academic_vault_path');
    });
  }

  Future<void> _pickVaultFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('academic_vault_path', selectedDirectory);
      setState(() {
        _vaultPath = selectedDirectory;
      });
    }
  }

  Future<void> _loadIndex() async {
    await _searchService.init();
    setState(() {
      _documents = _searchService.getAllDocuments();
    });
  }

  Future<void> _scanDeviceForAcademicFiles() async {
    setState(() {
      _isScanning = true;
      _scanStatus =
          "Requesting permissions and scanning ${_vaultPath ?? 'device storage'}...";
    });

    final files = await FileTraversalService.findAcademicVaultFiles(
      customDirectory: _vaultPath,
    );

    setState(() {
      _scanStatus = "Found ${files.length} potential documents. Indexing...";
    });

    int added = 0;
    // We only process up to 5 so we don't blow up the API limit during Hackathon demo
    for (var path in files.take(5)) {
      // Skip if already in index
      if (_documents.any((doc) => doc.path == path)) continue;

      setState(() {
        _scanStatus = "Indexing: ${path.split('/').last}";
      });

      final newDoc = await DocumentIndexer.analyzeDocument(path);
      if (newDoc != null) {
        await _searchService.saveDocumentToIndex(newDoc);
        added++;
        setState(() {
          _documents = _searchService.getAllDocuments();
        });
      }
    }

    setState(() {
      _isScanning = false;
      _scanStatus =
          "Scan complete. ${files.length} files found, $added new files indexed.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Vault Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickVaultFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text(
                      'Select Vault Folder',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanDeviceForAcademicFiles,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.manage_search),
                    label: Text(
                      _isScanning ? 'Scanning...' : 'Scan Vault',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_vaultPath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Selected Vault: $_vaultPath',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          if (_scanStatus.isNotEmpty && _scanStatus != "Idle")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _scanStatus,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const Divider(),
          Expanded(
            child: _documents.isEmpty
                ? const Center(
                    child: Text('Your library is empty. Scan for documents!'),
                  )
                : ListView.builder(
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          doc.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          doc.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
