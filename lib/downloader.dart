import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart' as path;

class FileInfo {
  final String fileName;
  final String savePath;

  FileInfo({required this.fileName, required this.savePath});
}

class FileStatus {
  final String savePath;
  final String status;
  final String? reason;

  FileStatus({required this.savePath, required this.status, this.reason});
}

class Downloader {
  final int maxRedirects = 10;

  Future<List<FileStatus>> downloadDirectoriesFromFolder(
      String folderUrl, String saveFolder, Set<String> extensions) async {
    var response = await http.get(Uri.parse(folderUrl));

    List<FileStatus> fileStatuses = [];


    if (response.statusCode == 200) {
      var lines = response.body.split('\n');

      for (var line in lines) {
        if (line.contains('<a href="') && line.contains('/')) {
          if (line.contains('synco') ||
              line.contains("PARENTDIR") ||
              line.contains("ICO")) {
            continue;
          }

          var startIndex = line.indexOf('<a href="') + 9;
          var endIndex = line.indexOf('"', startIndex);

          if (startIndex < endIndex) {
            var subdirectoryName = line.substring(startIndex, endIndex);
            subdirectoryName = Uri.decodeComponent(subdirectoryName);

            if (subdirectoryName != '../') {
              var subdirectoryUrl =
                  Uri.parse(folderUrl).resolve(subdirectoryName).toString();
              var saveSubdirectoryPath =
                  path.join(saveFolder, subdirectoryName);

              var directory = Directory(saveSubdirectoryPath);
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }

              final fileStatus = await downloadFilesFromFolder(
                  subdirectoryUrl, saveSubdirectoryPath, extensions);
              fileStatuses.addAll(fileStatus);
            }
          }
        }
      }
    } else {
      print('Failed to fetch directories: ${response.statusCode}');
    }

    return fileStatuses;
  }

  Future<FileStatus> downloadFile(String fileUrl, String savePath) async {
    final file = File(savePath);

    // Create necessary directories if they do not exist
    try {
      final directory =
          file.parent; // Get the directory path from the file path
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Directory created: ${directory.path}');
      }
    } catch (e) {
      print('Failed to create directory: $e');
      return FileStatus(
          savePath: savePath,
          status: 'Failed',
          reason: 'Failed to create directory');
    }

    // Check if file already exists
    if (await file.exists()) {
      print('File already exists at: $savePath');
      return FileStatus(
          savePath: savePath,
          status: 'Not Downloaded',
          reason: 'File already exists');
    }

    print('Starting download for: $fileUrl');

    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('File downloaded to: $savePath');
        return FileStatus(
            savePath: savePath,
            status: 'Success');
      } else {
        print('Failed to download file: ${response.statusCode}');
        return FileStatus(
            savePath: savePath,
            status: 'Failed',
            reason: 'Failed to download with status ${response.statusCode}');
      }
    } catch (e) {
      print('Download failed: $e');
      return FileStatus(
          savePath: savePath,
          status: 'Failed',
          reason: 'Failed to download');
    }
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
      print('File deleted: $filePath');
    } else {
      print('File not found: $filePath');
    }
  }

  Future<List<FileInfo>> listFilesFromFolder(
      String folderUrl, String saveFolder, Set<String> extensions) async {
    var response = await http.get(Uri.parse(folderUrl));

    if (response.statusCode == 200) {
      var lines = response.body.split('\n');
      List<FileInfo> files = [];

      for (var line in lines) {
        if (_containsAnyExtension(line, extensions) &&
            line.contains('<a href="')) {
          var startIndex = line.indexOf('<a href="') + 9;
          var endIndex = line.indexOf('"', startIndex);

          if (startIndex < endIndex) {
            var filename = line.substring(startIndex, endIndex);

            if (filename != '../' && !filename.endsWith('/')) {
              var fileUrl = Uri.parse(folderUrl).resolve(filename).toString();
              var savePath = path.join(saveFolder, filename);

              files.add(FileInfo(fileName: filename, savePath: savePath));
            }
          }
        }
      }

      return files;
    } else {
      print('Failed to fetch files: ${response.statusCode}');
      return [];
    }
  }

  Future<List<FileStatus>> downloadFilesFromFolder(
      String folderUrl, String saveFolder, Set<String> extensions) async {
    var response = await http.get(Uri.parse(folderUrl));

    List<FileStatus> files = [];

    if (response.statusCode == 200) {
      var lines = response.body.split('\n');

      for (var line in lines) {
        if (_containsAnyExtension(line, extensions) &&
            line.contains('<a href="')) {
          var startIndex = line.indexOf('<a href="') + 9;
          var endIndex = line.indexOf('"', startIndex);

          if (startIndex < endIndex) {
            var filename = line.substring(startIndex, endIndex);

            if (filename != '../' && !filename.endsWith('/')) {
              String fileUrl = folderUrl.endsWith('/')
                  ? '$folderUrl$filename'
                  : '$folderUrl/$filename';
              var savePath = path.join(saveFolder, filename);

              final result = await downloadFile(fileUrl, savePath);
              files.add(result);
            }
          }
        }
      }
    } else {
      print('Failed to fetch files: ${response.statusCode}');
    }

    return files;
  }

  bool _containsAnyExtension(String line, Set<String> extensions) {
    for (var ext in extensions) {
      if (line.contains(ext)) {
        return true;
      }
    }
    return false;
  }

  String decodeFilename(String filename) {
    return Uri.decodeComponent(filename);
  }

  String sanitizeFilename(String filename) {
    // Replace characters that are not allowed in filenames
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Replace invalid characters
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove non-ASCII characters
        .trim(); // Trim any leading or trailing spaces
  }

  Future<http.Response> _getWithRedirectHandling(Uri url) async {
    var client = http.Client();
    var request = http.Request('GET', url);
    var response = await client.send(request);

    var redirects = 0;
    while (response.statusCode >= 300 && response.statusCode < 400) {
      if (redirects >= maxRedirects) {
        throw ClientException('Too many redirects');
      }
      redirects++;
      var location = response.headers['location'];
      if (location == null) {
        throw ClientException('No location header for redirect');
      }
      url = Uri.parse(location);
      response = await client.send(http.Request('GET', url));
    }

    return http.Response.fromStream(response);
  }
}
