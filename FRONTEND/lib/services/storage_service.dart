import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/contract_model.dart';

class StorageService {
  static const _emailKey = 'user_email';
  static const _historyKey = 'contract_history';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) != null;
  }

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveAnalysis(ContractAnalysis analysis) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    history.insert(0, json.encode(analysis.toJson()));
    if (history.length > 20) history = history.sublist(0, 20);
    await prefs.setStringList(_historyKey, history);
  }

  static Future<List<ContractAnalysis>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    return history
        .map((item) => ContractAnalysis.fromJson(json.decode(item)))
        .toList();
  }
}
