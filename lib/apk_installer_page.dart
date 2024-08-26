import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApkInstallerPage extends StatefulWidget {
  const ApkInstallerPage({super.key});

  @override
  _ApkInstallerPageState createState() => _ApkInstallerPageState();
}

class _ApkInstallerPageState extends State<ApkInstallerPage> {
  List<String> apkFiles = [];
  bool isLoading = true;
  String directory = "apps";

  @override
  void initState() {
    super.initState();
    fetchApkFiles();
  }

  Future<void> fetchApkFiles() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.46:8000/list?directory=$directory'));

      if (response.statusCode == 200) {
        setState(() {
          apkFiles = List<String>.from(json.decode(response.body)['items']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load files');
      }
    } catch (e) {
      print('Error fetching files: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadAndInstallApk(String fileName) async {
    try {
      // Fetching the APK file from the server
      final response = await http.get(Uri.parse('http://192.168.0.46/synco/$fileName'));

      if (response.statusCode == 200) {
        // Get the directory to store the downloaded APK
        final directory = await getExternalStorageDirectory();
        final appDir = Directory('${directory?.path}/apps');

        // Ensure the directory exists
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }

        final filePath = '${directory?.path}/$fileName';

        // Save the APK file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Install the APK
        final result = await OpenFilex.open(filePath);
        if (result.type == ResultType.done) {
          print("Installation started.");
        } else {
          print("Installation failed: ${result.message}");
        }
      } else {
        throw Exception('Failed to download APK');
      }
    } catch (e) {
      print('Error downloading and installing APK: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APK Installer'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: apkFiles.length,
        itemBuilder: (context, index) {
          final fileName = apkFiles[index];
          return ListTile(
            title: Text(fileName),
            onTap: () => downloadAndInstallApk(fileName),
          );
        },
      ),
    );
  }
}
