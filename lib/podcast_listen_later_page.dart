import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:synco_de_my_phone/model/podcast_episode.dart';
import 'dart:convert';
import 'dart:io';
import 'config.dart';
import 'downloader.dart';
import 'search_box.dart';

class PodcastListenLaterPage extends StatefulWidget {

  const PodcastListenLaterPage({super.key});

  @override
  _PodcastListenLaterPageState createState() => _PodcastListenLaterPageState();
}

class _PodcastListenLaterPageState extends State<PodcastListenLaterPage> {
  List<PodcastEpisode> episodes = [];
  List<PodcastEpisode> filteredEpisodes = [];
  final Downloader downloader = Downloader();
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'tempUserId': Config.tempUserId
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
            '${Config.sorg}/podcast/listenLater?page=$page&size=20'),
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
                  content.map((val) => PodcastEpisode.fromJson(val)).toList());
              filteredEpisodes = episodes;
              page++;
            });
          }
        }
      } else {
        throw Exception('Failed to load episodes');
      }
    } catch (e) {
      throw Exception('Failed to load episodes $e');
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
        title: const Text('Podcast Listen Later'),
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
                          // leading: Image.network(podcast.coverUrl),
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
                          // leading: Image.network(podcast.coverUrl),
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
                          // leading: Image.network(podcast.coverUrl),
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
