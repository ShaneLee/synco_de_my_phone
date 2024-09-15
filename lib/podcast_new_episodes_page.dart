import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:synco_de_my_phone/model/podcast_episode.dart';
import 'package:synco_de_my_phone/podcast_episode_page.dart';
import 'dart:convert';
import 'dart:io';
import 'config.dart';
import 'downloader.dart';

class PodcastNewEpisodesPage extends StatefulWidget {
  const PodcastNewEpisodesPage({super.key});

  @override
  _PodcastNewEpisodesPageState createState() => _PodcastNewEpisodesPageState();
}

class _PodcastNewEpisodesPageState extends State<PodcastNewEpisodesPage> {
  late Future<List<PodcastEpisode>> podcasts;
  final Downloader downloader = Downloader();
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'tempUserId': Config.tempUserId
  };

  @override
  void initState() {
    super.initState();
    podcasts = fetchPodcasts();
  }

  Future<List<PodcastEpisode>> fetchPodcasts() async {
    final response = await http.get(
      headers: headers,
      Uri.parse(
          '${Config.sorg}/podcast/new?page=0&size=50&sort=publishedDate,desc'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> content = data['content'];

      // Debug output to check data
      print('Fetched podcasts data: $content');

      return content.map((podcast) => PodcastEpisode.fromJson(podcast)).toList();
    } else {
      throw Exception('Failed to load podcasts');
    }
  }

  Future<void> _refreshPodcasts() async {
    setState(() {
      podcasts = fetchPodcasts(); // Fetch the data again
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPodcasts,
        child: FutureBuilder<List<PodcastEpisode>>(
          future: podcasts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No podcasts found'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final podcast = snapshot.data![index];
                  final savePath =
                      '/storage/sdcard1/Podcasts/${podcast.fileName}';

                  return FutureBuilder<bool>(
                    future: File(savePath).exists(),
                    builder: (context, fileSnapshot) {
                      if (fileSnapshot.connectionState ==
                          ConnectionState.waiting) {
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

                        return PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'episodes') {
                              // Navigate to the PodcastEpisodesPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PodcastEpisodesPage(
                                      podcastTitle: podcast.podcastTitle,
                                      podcastId: podcast.id),
                                ),
                              );
                            } else if (value == 'download') {
                              if (fileExists) {
                                _deleteFile(savePath);
                              } else {
                                setState(() {
                                  // Update UI for download status
                                });
                                downloader
                                    .downloadFile(podcast.url, savePath)
                                    .then((_) {
                                  setState(() {
                                    // Refresh UI to reflect the downloaded status
                                  });
                                });
                              }
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'episodes',
                              child: Text('View Episodes'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'download',
                              child: Text('Download/Delete'),
                            ),
                          ],
                          child: ListTile(
                            leading: Image.network(podcast.coverUrl),
                            title: Text(podcast.episodeTitle),
                            subtitle: Text(statusText),
                            trailing: Icon(icon),
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
              );
            }
          },
        ),
      ),
    );
  }
}
