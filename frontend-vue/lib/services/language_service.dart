import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String languageKey = 'selected_language';
  static const String english = 'English';
  static const String thai = 'ไทย';

  static final ValueNotifier<String> notifier = ValueNotifier<String>(thai);

  static String get currentLanguage => notifier.value;
  static bool get isThai => currentLanguage == thai;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getString(languageKey) ?? thai;
  }

  static Future<void> changeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, language);
    notifier.value = language;
  }

  static String text({required String en, required String th}) {
    return isThai ? th : en;
  }
}
