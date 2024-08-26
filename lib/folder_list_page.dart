import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'file_list_page.dart';

class FolderInfo {
  final String folderName;
  final String folderUrl;

  FolderInfo({required this.folderName, required this.folderUrl});
}

class FolderListPage extends StatefulWidget {
  final String rootUrl;
  final String saveFolder;
  final Set<String> extensions;

  const FolderListPage({super.key, required this.rootUrl, required this.saveFolder, required this.extensions});

  @override
  _FolderListPageState createState() => _FolderListPageState();
}

class _FolderListPageState extends State<FolderListPage> {
  late Future<List<FolderInfo>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = listFoldersFromUrl(widget.rootUrl);
  }

  Future<List<FolderInfo>> listFoldersFromUrl(String folderUrl) async {
    var response = await http.get(Uri.parse(folderUrl));

    if (response.statusCode == 200) {
      var lines = response.body.split('\n');
      List<FolderInfo> folders = [];

      for (var line in lines) {
        if (line.contains('<a href="') && line.contains('/') && !line.contains('../')) {
          var startIndex = line.indexOf('<a href="') + 9;
          var endIndex = line.indexOf('"', startIndex);

          if (startIndex < endIndex) {
            var folderName = line.substring(startIndex, endIndex);
            folderName = Uri.decodeComponent(folderName);

            if (folderName != '../') {
              var folderUrl = Uri.parse(widget.rootUrl).resolve(folderName).toString();
              folders.add(FolderInfo(folderName: folderName, folderUrl: folderUrl));
            }
          }
        }
      }

      return folders;
    } else {
      print('Failed to fetch folders: ${response.statusCode}');
      return [];
    }
  }

  void _openFolder(FolderInfo folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileListPage(
          folderUrl: folder.folderUrl,
          saveFolder: path.join(widget.saveFolder, folder.folderName),
          extensions: widget.extensions,
        ),
      ),
    );
  }

  Widget _buildFolderList(List<FolderInfo> folders) {
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return ListTile(
          title: Text(folder.folderName),
          onTap: () {
            _openFolder(folder);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folders in ${widget.rootUrl}'),
      ),
      body: FutureBuilder<List<FolderInfo>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No folders found.'));
          } else {
            return _buildFolderList(snapshot.data!);
          }
        },
      ),
    );
  }
}
