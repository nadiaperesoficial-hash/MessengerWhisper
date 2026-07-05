import 'package:shared_preferences/shared_preferences.dart';

class WallpaperService {
  static const _prefsKey = 'chat_wallpaper_asset';
  static const defaultWallpaper = 'assets/wallpapers/native.png';

  static const availableWallpapers = <String>[
    'assets/wallpapers/native.png',
    'assets/wallpapers/option1.png',
    'assets/wallpapers/option2.png',
    'assets/wallpapers/option3.png',
    'assets/wallpapers/option4.png',
  ];

  Future<String> getSelectedWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? defaultWallpaper;
  }

  Future<void> setSelectedWallpaper(String assetPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, assetPath);
  }
}
