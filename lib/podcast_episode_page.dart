import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:synco_de_my_phone/client/podcast_client.dart';
import 'package:synco_de_my_phone/model/podcast_episode.dart';
import 'dart:convert';
import 'dart:io';
import 'config.dart';
import 'downloader.dart';
import 'menus/episode_long_press_menu.dart';
import 'search_box.dart';

class PodcastEpisodesPage extends StatefulWidget {
  final String podcastTitle;
  final String podcastId;

  const PodcastEpisodesPage(
      {super.key, required this.podcastTitle, required this.podcastId});

  @override
  _PodcastEpisodesPageState createState() => _PodcastEpisodesPageState();
}

class _PodcastEpisodesPageState extends State<PodcastEpisodesPage> {
  List<PodcastEpisode> episodes = [];
  List<PodcastEpisode> filteredEpisodes = [];
  final Downloader downloader = Downloader();
  final PodcastClient client = PodcastClient();
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
            '${Config.sorg}/podcast/episodes?podcastId=${widget.podcastId}&page=$page&size=20'),
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
      // Handle error
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

  Future<void> _deleteFile(String filePath, PodcastEpisode episode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text(
            'Have you listened to this file? Are you sure you want to delete it and mark it as played?'),
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
      await client
          .track(episode.id)
          .then((val) => downloader.deleteFile(filePath));
      setState(() {}); // Refresh UI
    }
  }

  void _filterEpisodes(String query) {
    setState(() {
      filteredEpisodes = episodes
          .where((episode) =>
          episode.episodeTitle.toLowerCase().contains(query.toLowerCase()))
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
                  final savePath =
                      '/storage/sdcard1/Podcasts/${podcast.fileName}';

                  return FutureBuilder<bool>(
                    future: File(savePath).exists(),
                    builder: (context, fileSnapshot) {
                      if (fileSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          leading: podcast.coverUrl != null
                              ? Image.network(podcast.coverUrl!)
                              : null,
                          title: Text(podcast.episodeTitle),
                          subtitle: const Text('Checking file status...'),
                          trailing: const CircularProgressIndicator(),
                        );
                      } else if (fileSnapshot.hasData) {
                        final fileExists = fileSnapshot.data == true;
                        final icon = fileExists ? Icons.delete : Icons.download;
                        final statusText =
                        fileExists ? 'File exists' : 'File not downloaded';

                        return EpisodeLongPressMenu(
                          episode: podcast,
                          client: client,
                          downloader: downloader,
                          savePath: savePath,
                          fileExists: fileExists,
                          onMarkedAsListened: () {
                            setState(() {
                              // Handle the UI refresh after marking as listened
                            });
                          },
                          onDeleteFile: _deleteFile,
                        );
                      } else {
                        return ListTile(
                          leading: podcast.coverUrl != null
                              ? Image.network(podcast.coverUrl!)
                              : null,
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
            )
          ],
        ),
      ),
    );
  }
}
