import 'package:flutter/material.dart';
import 'downloader.dart';

class GenericDownloadPage extends StatefulWidget {
  @override
  _GenericDownloadPageState createState() => _GenericDownloadPageState();
}

class _GenericDownloadPageState extends State<GenericDownloadPage> {
  Downloader downloader = Downloader();
  List<FileStatus> downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeDownloads();
  }

  Future<void> _initializeDownloads() async {
    await _download();
  }

  Future<void> _download() async {
    final ebooks = await downloader.downloadFilesFromFolder(
        'http://192.168.0.46/synco/books/books-to-sync', '/storage/emulated/0/kindle/', {'.mobi'});
    final music = await downloader.downloadDirectoriesFromFolder(
        'http://192.168.0.46/synco/music/', '/storage/sdcard1/Music/', {'.mp3'});
    final audiobooks = await downloader.downloadDirectoriesFromFolder(
        'http://192.168.0.46/synco/audiobooks/', '/storage/sdcard1/Audiobooks/', {".mp3", ".mp4", ".m4a"});

    setState(() {
      downloadedFiles.addAll(ebooks);
      downloadedFiles.addAll(music);
      downloadedFiles.addAll(audiobooks);
    });
  }

  Future<void> _refreshFiles() async {
    setState(() {
      downloadedFiles.clear();
    });
    await _download();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generic Downloads'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFiles,
        child: ListView.builder(
          itemCount: downloadedFiles.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                downloadedFiles[index].savePath,
              ),
              subtitle: Text(
                downloadedFiles[index].status == 'success'
                    ? downloadedFiles[index].status
                    : '${downloadedFiles[index].status} - ${downloadedFiles[index].reason ?? ''}',
                style: TextStyle(
                  color: downloadedFiles[index].status == 'success' ? Colors.black : Colors.red,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
