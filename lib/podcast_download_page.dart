import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:synco_de_my_phone/podcast_episode_page.dart';
import 'dart:convert';
import 'config.dart';
import 'downloader.dart';

class Podcast {
  final String id;
  final String podcastTitle;
  final String? author;
  final String? coverUrl;

  Podcast({

    required this.id,
    required this.podcastTitle,
    this.author,
    this.coverUrl,
  });

  // TODO move these model files and make better
  // TODO make a specific http client
  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'],
      podcastTitle: json['podcastTitle'],
      coverUrl: json['coverUrl'],
      author: json['author'],
    );
  }
}

class PodcastDownloadPage extends StatefulWidget {
  const PodcastDownloadPage({super.key});

  @override
  _PodcastDownloadPageState createState() => _PodcastDownloadPageState();
}

class _PodcastDownloadPageState extends State<PodcastDownloadPage> {
  late Future<List<Podcast>> podcasts;
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

  Future<List<Podcast>> fetchPodcasts() async {
    final response = await http.get(
      headers: headers,
      Uri.parse(
          '${Config.sorg}/podcast/subscribed?page=0&size=50&sort=createdAtUtc,desc'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> content = data['content'];

      return content.map((podcast) => Podcast.fromJson(podcast)).toList();
    } else {
      throw Exception('Failed to load podcasts');
    }
  }

  Future<void> _refreshPodcasts() async {
    setState(() {
      podcasts = fetchPodcasts(); // Fetch the data again
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPodcasts,
        child: FutureBuilder<List<Podcast>>(
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

                  return FutureBuilder<bool>(
                    builder: (context, fileSnapshot) {
                      if (fileSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                        // TODO - need the coverUrl from the backend
                          // leading: Image.network(podcast.coverUrl),
                          title: Text(podcast.podcastTitle),
                        );
                      }

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
                            }
                            if (value == 'unsubscribe') {
                              // TODO unsubscribe
                              print("not implemented boyo.");

                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'episodes',
                              child: Text('View Episodes'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'unsubscribe',
                              child: Text('Unsubscribe'),
                            ),
                          ],
                          child: ListTile(
    // TODO need the cover from the backend
                            // leading: Image.network(podcast.coverUrl),
                            title: Text(podcast.podcastTitle),
                            subtitle: Text('Author: ${podcast.author}'),
                            // trailing: Icon(icon),
                          ),
                        );
                      // TODO don't know what I need to do here
                      }, future: null,
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
