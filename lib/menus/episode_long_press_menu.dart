import 'package:flutter/material.dart';
import 'package:synco_de_my_phone/client/podcast_client.dart';
import 'package:synco_de_my_phone/model/podcast_episode.dart';

import '../downloader.dart';
import '../podcast_episode_page.dart';

class EpisodeLongPressMenu extends StatelessWidget {
  final PodcastEpisode episode;
  final PodcastClient client;
  final Downloader downloader;
  final String savePath;
  final bool fileExists;
  final VoidCallback onMarkedAsListened;
  final Future<void> Function(String filePath, PodcastEpisode episode)
  onDeleteFile;

  EpisodeLongPressMenu({
    required this.episode,
    required this.client,
    required this.downloader,
    required this.savePath,
    required this.fileExists,
    required this.onMarkedAsListened,
    required this.onDeleteFile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        final selectedValue = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(200, 200, 100, 100),
          items: [
            const PopupMenuItem(
              value: 'mark_listened',
              child: Text('Mark as listened'),
            ),
            const PopupMenuItem(
              value: 'episodes',
              child: Text('View Episodes'),
            ),
            PopupMenuItem(
              value: 'download',
              child: Text(fileExists ? 'Delete File' : 'Download File'),
            ),
          ],
        );

        // Check if context is still valid
        if (context.mounted) {
          switch (selectedValue) {
            case 'mark_listened':
              await client.track(episode.id);
              onMarkedAsListened();
              break;

            case 'episodes':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PodcastEpisodesPage(
                    podcastTitle: episode.podcastTitle ?? '',
                    podcastId: episode.id,
                  ),
                ),
              );
              break;

            case 'download':
              if (fileExists) {
                await onDeleteFile(savePath, episode);
              } else {
                await downloader.downloadFile(episode.url, savePath);
                onMarkedAsListened(); // Refresh UI to reflect changes
              }
              break;

            default:
              break;
          }
        }
      },
      child: ListTile(
        leading: episode.coverUrl != null ? Image.network(episode.coverUrl!) : null,
        title: Text(episode.episodeTitle),
        subtitle: const Text('Hold to show options'),
      ),
    );
  }
}
