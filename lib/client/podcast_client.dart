import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:synco_de_my_phone/model/podcast_episode.dart';

import '../config.dart';
import '../flutter_local_notifications.dart';

class PodcastClient {

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'tempUserId': Config.tempUserId
  };

  Future<void> fetchNewPodcastEpisodes() async {
    final response = await http.get(
        Uri.parse(
            '${Config
                .sorg}/podcast/new?sinceDays=1&page=0&size=3&sort=publishedDate,desc'),
        headers: headers
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> content = data['content'];
      final episodes = content.map((podcast) =>
          PodcastEpisode.fromJson(podcast)).toList();

      for (var episode in episodes) {
        await showNotification(episode.podcastTitle, episode.episodeTitle);
      }
    } else {
      print('Failed to fetch episodes: ${response.statusCode}');
    }
  }
}
