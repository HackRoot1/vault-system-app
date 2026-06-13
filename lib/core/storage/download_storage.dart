import 'package:shared_preferences/shared_preferences.dart';

class DownloadStorage {
  const DownloadStorage._();

  static const _downloadDirectoryKey = 'download_directory_path';

  static Future<void> saveDownloadDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadDirectoryKey, path);
  }

  static Future<String?> getDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_downloadDirectoryKey);
  }

  static Future<void> clearDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadDirectoryKey);
  }
}
