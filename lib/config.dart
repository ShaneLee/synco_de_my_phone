import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String? get server => dotenv.env['SERVER'];
  static String? get synco => dotenv.env['SYNCO'];
  static String? get sorg => dotenv.env['SORG'];
  static String get tempUserId => dotenv.env['TEMP_USER_ID'] ?? '';
}
