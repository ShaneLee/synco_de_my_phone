import 'package:flutter/material.dart';
import 'config.dart';
import 'downloader.dart';

class GenericDownloadPage extends StatefulWidget {
  const GenericDownloadPage({super.key});

  @override
  _GenericDownloadPageState createState() => _GenericDownloadPageState();
}

class _GenericDownloadPageState extends State<GenericDownloadPage> {
  Downloader downloader = Downloader();
  List<FileStatus> downloadedFiles = [];
  int notDownloadedCount = 0;

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
        '${Config.server}/synco/books/books-to-sync',
        '/storage/emulated/0/kindle/',
        {'.mobi'});
    final music = await downloader.downloadDirectoriesFromFolder(
        '${Config.server}/synco/music/', '/storage/sdcard1/Music/', {'.mp3'});
    final audiobooks = await downloader.downloadDirectoriesFromFolder(
        '${Config.server}/synco/audiobooks/',
        '/storage/sdcard1/Audiobooks/',
        {".mp3", ".mp4", ".m4a"});

    setState(() {
      downloadedFiles = [...ebooks, ...music, ...audiobooks];

      // Filter the list to only include files with a status of 'success'
      downloadedFiles =
          downloadedFiles.where((file) => file.status == 'success').toList();

      // Count the number of files that were not downloaded successfully
      notDownloadedCount = ebooks.length +
          music.length +
          audiobooks.length -
          downloadedFiles.length;
    });
  }

  Future<void> _refreshFiles() async {
    setState(() {
      downloadedFiles.clear();
      notDownloadedCount = 0;
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
        child: Column(
          children: [
            // Display the count of files that weren't downloaded successfully
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Files that were not downloaded: $notDownloadedCount',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: downloadedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      downloadedFiles[index].savePath,
                    ),
                    subtitle: Text(
                      downloadedFiles[index].status,
                      style: TextStyle(
                        color: downloadedFiles[index].status == 'success'
                            ? Colors.black
                            : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
