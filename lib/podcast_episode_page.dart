import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'downloader.dart';
import 'search_box.dart';

class Podcast {
  final String episodeTitle;
  final String fileName;
  final String coverUrl;
  final String url;

  Podcast({
    required this.episodeTitle,
    required this.fileName,
    required this.coverUrl,
    required this.url,
  });

  static String sanitizeFilename(String filename) {
    return filename
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .trim();
  }

  static String sanitizeEpisodeName(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '')
        .trim();
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      episodeTitle: sanitizeEpisodeName(json['episodeTitle']),
      fileName: '${sanitizeFilename(json['episodeTitle'])}.mp3',
      coverUrl: json['coverUrl'],
      url: json['url'],
    );
  }
}

class PodcastEpisodesPage extends StatefulWidget {
  final String podcastTitle;
  final String podcastId;

  PodcastEpisodesPage({super.key, required this.podcastTitle, required this.podcastId});

  @override
  _PodcastEpisodesPageState createState() => _PodcastEpisodesPageState();
}

class _PodcastEpisodesPageState extends State<PodcastEpisodesPage> {
  List<Podcast> episodes = [];
  List<Podcast> filteredEpisodes = [];
  final Downloader downloader = Downloader();
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'tempUserId': 'bd11dcc2-77f6-430f-8e87-5839d31ab0e3',
  };
  bool isLoading = false;
  bool hasMore = true;
  int page = 0;

  @override
  void initState() {
    super.initState();
    fetchEpisodes();
  }

  Future<void> fetchEpisodes() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        headers: headers,
        Uri.parse(
            'http://192.168.0.46:8080/podcast/episodes?podcastId=${widget.podcastId}&page=$page&size=20'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> content = data['content'];

        if (content.isEmpty) {
          if (mounted) {
            setState(() {
              hasMore = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              episodes.addAll(
                  content.map((podcast) => Podcast.fromJson(podcast)).toList());
              filteredEpisodes = episodes;
              page++;
            });
          }
        }
      } else {
        throw Exception('Failed to load episodes');
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEpisodes() async {
    setState(() {
      episodes.clear();
      filteredEpisodes.clear();
      page = 0;
      hasMore = true;
    });
    fetchEpisodes();
  }

  Future<void> _deleteFile(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text(
            'Have you listened to this file? Are you sure you want to delete it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await downloader.deleteFile(filePath);
      setState(() {}); // Refresh UI
    }
  }

  void _filterEpisodes(String query) {
    setState(() {
      filteredEpisodes = episodes
          .where((episode) => episode.episodeTitle.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.podcastTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEpisodes,
        child: Column(
          children: [
            SearchBox(onSearch: _filterEpisodes),
            Expanded(
              child: ListView.builder(
                itemCount: filteredEpisodes.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filteredEpisodes.length) {
                    fetchEpisodes();
                    return const Center(child: CircularProgressIndicator());
                  }

                  final podcast = filteredEpisodes[index];
                  final savePath = '/storage/sdcard1/Podcasts/${podcast.fileName}';

                  return FutureBuilder<bool>(
                    future: File(savePath).exists(),
                    builder: (context, fileSnapshot) {
                      if (fileSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          leading: Image.network(podcast.coverUrl),
                          title: Text(podcast.episodeTitle),
                          subtitle: const Text('Checking file status...'),
                          trailing: const CircularProgressIndicator(),
                        );
                      } else if (fileSnapshot.hasData) {
                        final fileExists = fileSnapshot.data == true;
                        final icon = fileExists ? Icons.delete : Icons.download;
                        final statusText =
                        fileExists ? 'File exists' : 'File not downloaded';

                        return ListTile(
                          leading: Image.network(podcast.coverUrl),
                          title: Text(podcast.episodeTitle),
                          subtitle: Text(statusText),
                          trailing: IconButton(
                            icon: Icon(icon),
                            onPressed: () async {
                              if (fileExists) {
                                await _deleteFile(savePath);
                              } else {
                                setState(() {
                                  // Update UI for download status
                                });
                                await downloader.downloadFile(podcast.url, savePath);
                                setState(() {
                                  // Refresh UI to reflect the downloaded status
                                });
                              }
                            },
                          ),
                        );
                      } else {
                        return ListTile(
                          leading: Image.network(podcast.coverUrl),
                          title: Text(podcast.episodeTitle),
                          subtitle: const Text('Error checking file status'),
                          trailing: IconButton(
                            icon: const Icon(Icons.error),
                            onPressed: () {},
                          ),
                        );
                      }
                    },
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
