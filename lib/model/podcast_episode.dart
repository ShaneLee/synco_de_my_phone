class PodcastEpisode {
  final String id;
  final String podcastTitle;
  final String episodeTitle;
  final String fileName;
  final String coverUrl;
  final String url;


  PodcastEpisode({

    required this.id,
    required this.podcastTitle,
    required this.episodeTitle,
    required this.fileName,
    required this.coverUrl,
    required this.url,
  });

  static String sanitizeFilename
      (String filename) {
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

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    return PodcastEpisode(
      id: json['podcastId'],
      podcastTitle: json['podcastTitle'],
      episodeTitle: sanitizeEpisodeName(json['episodeTitle']),
      fileName: '${sanitizeFilename(json['episodeTitle'])}.mp3',
      coverUrl: json['coverUrl'],
      url: json['url'],
    );
  }
}
