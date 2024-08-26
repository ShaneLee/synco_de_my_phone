import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:synco_de_my_phone/downloader.dart';
import 'audio_player_manager.dart';
import 'search_box.dart';

class FileInfo {
  final String fileName;
  final String? url;
  final String savePath;

  FileInfo({required this.fileName, required this.savePath, this.url});
}

class FileListPage extends StatefulWidget {
  final String folderUrl;
  final String saveFolder;
  final Set<String> extensions;

  const FileListPage({super.key, required this.folderUrl, required this.saveFolder, required this.extensions});

  @override
  _FileListPageState createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  late Future<List<FileInfo>> _filesFuture;
  List<FileInfo> _allFiles = [];
  List<FileInfo> _filteredFiles = [];
  final Downloader downloader = Downloader();
  AudioPlayerManager? _audioPlayerManager;

  @override
  void initState() {
    super.initState();
    _filesFuture = listFilesFromFolder(widget.folderUrl, widget.saveFolder, widget.extensions);
  }

  @override
  void dispose() {
    _audioPlayerManager?.dispose();
    super.dispose();
  }

  Future<List<FileInfo>> listFilesFromFolder(String folderUrl, String saveFolder, Set<String> extensions) async {
    var response = await http.get(Uri.parse(folderUrl));

    if (response.statusCode == 200) {
      var lines = response.body.split('\n');
      List<FileInfo> files = [];

      for (var line in lines) {
        if (_containsAnyExtension(line, extensions) && line.contains('<a href="')) {
          var startIndex = line.indexOf('<a href="') + 9;
          var endIndex = line.indexOf('"', startIndex);

          if (startIndex < endIndex) {
            var filename = line.substring(startIndex, endIndex);

            if (filename != '../' && !filename.endsWith('/')) {
              var fileUrl = Uri.parse(folderUrl).resolve(filename).toString();
              var savePath = path.join(saveFolder, filename);

              files.add(FileInfo(
                  fileName: filename,
                  savePath: savePath,
                  url: fileUrl
              ));
            }
          }
        }
      }

      _allFiles = files;
      _filteredFiles = files;
      return files;
    } else {
      print('Failed to fetch files: ${response.statusCode}');
      return [];
    }
  }

  bool _containsAnyExtension(String line, Set<String> extensions) {
    for (var ext in extensions) {
      if (line.contains(ext)) {
        return true;
      }
    }
    return false;
  }

  void _playOrPauseAudio(FileInfo file) async {
    if (_audioPlayerManager == null) {
      _audioPlayerManager = AudioPlayerManager();
      final fileExists = await File(file.savePath).exists();

      if (fileExists) {
        await _audioPlayerManager!.setUpPlayer(file.savePath);
      } else if (file.url != null) {
        await _audioPlayerManager!.setUpPlayer(file.url!, isUrl: true);
      }
    }

    if (_audioPlayerManager!.isPlaying(file.savePath, file.url)) {
      await _audioPlayerManager!.pause();
    } else {
      await _audioPlayerManager!.play();
    }

    setState(() {}); // Update UI to reflect play/pause state
  }

  void _filterFiles(String query) {
    setState(() {
      _filteredFiles = _allFiles
          .where((file) => file.fileName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Widget _buildFileList(List<FileInfo> files) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          title: Text(file.fileName),
          subtitle: Text(file.savePath),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  await downloader.downloadFile(Uri.parse(widget.folderUrl).resolve(file.fileName).toString(), file.savePath);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await downloader.deleteFile(file.savePath);
                  setState(() {
                    _filesFuture = listFilesFromFolder(widget.folderUrl, widget.saveFolder, widget.extensions);
                  });
                },
              ),
              IconButton(
                icon: Icon(_audioPlayerManager?.isPlaying(file.url, file.savePath) ?? false ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  _playOrPauseAudio(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Files in ${widget.folderUrl}'),
      ),
      body: Column(
        children: [
          SearchBox(onSearch: _filterFiles),  // Add the search box here
          Expanded(
            child: FutureBuilder<List<FileInfo>>(
              future: _filesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No files found.'));
                } else {
                  return _buildFileList(_filteredFiles);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
