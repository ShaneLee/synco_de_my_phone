import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class FileUploadPage extends StatefulWidget {
  final String sourceDirectory;
  final String targetDirectory;
  final String title;

  const FileUploadPage({super.key,
    required this.sourceDirectory,
    required this.targetDirectory,
    required this.title,
  });

  @override
  _FileUploadPageState createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  List<File> filesToUpload = [];

  @override
  void initState() {
    super.initState();
    _findRecentFiles();
  }

  Future<void> _findRecentFiles() async {
    // Use the source directory passed into the widget
    final Directory directory = Directory(widget.sourceDirectory);
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // List all files in the directory
    List<FileSystemEntity> allFiles = directory.listSync(recursive: true);

    // Filter files that are less than 7 days old
    filesToUpload = allFiles
        .whereType<File>()
        .where((file) => file.lastModifiedSync().isAfter(sevenDaysAgo))
        .toList();

    // Check which files already exist on the server
    await _checkFilesOnServer();

    // Update the UI
    setState(() {});
  }

  Future<void> _checkFilesOnServer() async {
    List<String> localFileNames = filesToUpload.map((file) => path.basename(file.path)).toList();

    // Prepare the data for the diff API
    final request = http.MultipartRequest('POST', Uri.parse('http://192.168.0.46:8000/diff'));
    request.files.add(
      http.MultipartFile.fromString(
        'file',
        localFileNames.join('\n'),
        filename: 'file_list.txt',
      ),
    );

    // Send the request to the diff API
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final Map<String, dynamic> diffData = json.decode(responseBody);

      // Filter out files that already exist on the server
      List<String> missingFiles = List<String>.from(diffData['diff']);
      filesToUpload = filesToUpload.where((file) => missingFiles.contains(path.basename(file.path))).toList();
    }
  }

  Future<void> _uploadFile(File file) async {
    final fileName = path.relative(file.path, from: widget.sourceDirectory);

    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.0.46:8000/upload'));

    // Add the file part
    request.files.add(http.MultipartFile(
      'file',  // Field name for the file
      file.openRead(),
      await file.length(),
      filename: path.basename(file.path),
    ));

    // Add the file_path part
    request.fields['file_path'] = path.join(widget.targetDirectory, fileName);

    // Send the request
    var response = await request.send();

    if (response.statusCode == 200) {
      print('File uploaded: $fileName');
    } else {
      print('Failed to upload: $fileName, Status Code: ${response.statusCode}');
    }
  }



  Future<void> _uploadFiles() async {
    for (File file in filesToUpload) {
      await _uploadFile(file);
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Files uploaded successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: filesToUpload.isNotEmpty ? _uploadFiles : null,
          ),
        ],
      ),
      body: filesToUpload.isEmpty
          ? const Center(child: Text('No recent files to upload'))
          : ListView.builder(
        itemCount: filesToUpload.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(path.basename(filesToUpload[index].path)),
            subtitle: Text('Last Modified: ${filesToUpload[index].lastModifiedSync()}'),
          );
        },
      ),
    );
  }
}
