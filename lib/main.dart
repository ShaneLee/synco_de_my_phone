import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:synco_de_my_phone/client/podcast_client.dart';
import 'package:synco_de_my_phone/file_upload_page.dart';
import 'package:synco_de_my_phone/folder_list_page.dart';
import 'package:synco_de_my_phone/podcast_listen_later_page.dart';
import 'package:synco_de_my_phone/podcast_new_episodes_page.dart';
import 'apk_installer_page.dart';
import 'config.dart';
import 'generic_download_page.dart';
import 'podcast_download_page.dart';
import 'package:cron/cron.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> onSelectNotification(String? payload) async {
  if (payload != null) {
    switch (payload) {
      case 'navigate_to_new_episodes':
        navigatorKey.currentState?.push(
          MaterialPageRoute(
              builder: (context) => const PodcastNewEpisodesPage()),
        );
        break;
    }
  }
}

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  var cron = Cron();
  cron.schedule(Schedule.parse('30 5 * * *'), () async {
    await PodcastClient().fetchNewPodcastEpisodesAndNotify();
  });
  runApp(const MyApp());
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blueAccent,
  hintColor: Colors.teal,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Synco de my phone',
      home: const MyHomePage(),
      theme: darkTheme
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
                        saveFolder: '/storage/sdcard1/Audiobooks/',
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
                    sourceDirectory: 'storage/emulated/0//DCIM/Camera/',
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
