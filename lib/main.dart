import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:synco_de_my_phone/client/podcast_client.dart';
import 'package:synco_de_my_phone/file_upload_page.dart';
import 'package:synco_de_my_phone/folder_list_page.dart';
import 'package:synco_de_my_phone/podcast_listen_later_page.dart';
import 'package:synco_de_my_phone/podcast_new_episodes_page.dart';
import 'package:workmanager/workmanager.dart';
import 'apk_installer_page.dart';
import 'config.dart';
import 'generic_download_page.dart';
import 'podcast_download_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // if (task == 'fetchEpisodesTask') {
      try {
        await PodcastClient().fetchNewPodcastEpisodes();
        return Future.value(true);
      } catch (e) {
        print("Error in background task: $e");
        return Future.value(false);
      }
    // }
  });
}

Duration getInitialDelayFor5AM() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 5, 0); // 5 AM tomorrow

  Duration delay;
  if (now.hour < 5) {
    // It's before 5 AM today, schedule for 5 AM today
    delay = DateTime(now.year, now.month, now.day, 5, 0).difference(now);
  } else {
    // It's after 5 AM, schedule for 5 AM tomorrow
    delay = tomorrow.difference(now);
  }

  return delay;
}

Future<void> onSelectNotification(String? payload) async {
  if (payload != null) {
    switch (payload) {
      case 'navigate_to_new_episodes':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const PodcastNewEpisodesPage()),
        );
        break;
    }
  }
}

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  await Workmanager().registerPeriodicTask(
    'checkForNewEpisodes',
    'fetchEpisodesTask',
    initialDelay: getInitialDelayFor5AM(),
    frequency: const Duration(days: 1),
  );
  await PodcastClient().fetchNewPodcastEpisodes();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Synco de my phone',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synco de my phone'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GenericDownloadPage()),
                );
              },
              child: const Text('Go to Generic Downloads'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PodcastDownloadPage()),
                );
              },
              child: const Text('Go to Podcast Downloads'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PodcastNewEpisodesPage()),
                );
              },
              child: const Text('Go to new Podcast Episodes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PodcastListenLaterPage()),
                );
              },
              child: const Text('Go to new Podcast Listen Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                      FolderListPage(
                        rootUrl: '${Config.server}/synco/audiobooks-library/',
                        saveFolder:  '/storage/sdcard1/Audiobooks/',
                        extensions: const {'.mp3', '.mp4', '.m4a'},
                      ),
                  ),
                );
              },
              child: const Text('Go to Audiobook library'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                  const FileUploadPage(
                    sourceDirectory:  'storage/emulated/0//DCIM/Camera/',
                    targetDirectory: 'photos',
                    title: 'Upload Photos',
                  ),
                  ),
                );
              },
              child: const Text('Camera Uploads'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                  const ApkInstallerPage(),
                  ),
                );
              },
              child: const Text('App Installer'),
            ),
          ],
        ),
      ),
    );
  }
}
