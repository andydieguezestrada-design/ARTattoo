import 'package:shared_preferences/shared_preferences.dart';

/// Local protective limit for Gemini text chat.
/// This is intentionally separate from Google's actual project quota.
class ChatQuotaService {
  static const int dailyLimit = 30;
  static const _dateKey = 'chat_usage_date';
  static const _countKey = 'chat_usage_count';

  static Future<int> usedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    if (prefs.getString(_dateKey) != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_countKey, 0);
      return 0;
    }
    return prefs.getInt(_countKey) ?? 0;
  }

  static Future<bool> canChat() async => (await usedToday()) < dailyLimit;

  static Future<int> consume() async {
    final used = await usedToday();
    if (used >= dailyLimit) return used;
    final next = used + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, next);
    return next;
  }

  static String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
