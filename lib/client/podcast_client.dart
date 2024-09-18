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

  Future<List<PodcastEpisode>> getNewPodcastEpisodes() async {
    final response = await http.get(
        Uri.parse(
            '${Config
                .sorg}/podcast/new?sinceDays=1&page=0&size=3&sort=publishedDate,desc'),
        headers: headers
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> content = data['content'];
      return content.map((podcast) =>
          PodcastEpisode.fromJson(podcast)).toList();

    } else {
      print('Failed to fetch episodes: ${response.statusCode}');
    }

    return [];
  }

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
        await showNotification(episode.podcastTitle ?? 'New Episode', episode.episodeTitle);
      }
    } else {
      print('Failed to fetch episodes: ${response.statusCode}');
    }
  }

  Future<void> track(String episodeId) async {
    final body = jsonEncode({
      'episodeId': episodeId
    });

    final response = await http.put(
      Uri.parse('${Config.sorg}/podcast/track'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      print('Successfully tracked episode: $episodeId');
    } else {
      print('Failed to track episode: ${response.statusCode}');
    }
  }
}
