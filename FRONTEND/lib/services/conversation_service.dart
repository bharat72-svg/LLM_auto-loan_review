import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/conversation_model.dart';

class ConversationService {
  static const String _key = 'dealer_conversations';

  static Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = conversations.map((c) => c.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  static Future<List<Conversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Conversation.fromJson(json)).toList();
  }

  static Future<void> addConversation(Conversation conversation) async {
    final conversations = await loadConversations();
    conversations.add(conversation);
    await saveConversations(conversations);
  }

  static Future<void> updateConversation(Conversation updatedConversation) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == updatedConversation.id);
    
    if (index != -1) {
      conversations[index] = updatedConversation;
      await saveConversations(conversations);
    }
  }

  static Future<List<Conversation>> getConversationsForContract(String contractId) async {
    final all = await loadConversations();
    return all.where((c) => c.contractId == contractId).toList();
  }

  static Future<Conversation?> getConversationById(String id) async {
    final all = await loadConversations();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> addMessage(String conversationId, Message message) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == conversationId);
    
    if (index != -1) {
      final conv = conversations[index];
      final updatedConv = Conversation(
        id: conv.id,
        contractId: conv.contractId,
        dealerName: conv.dealerName,
        dealerEmail: conv.dealerEmail,
        messages: [...conv.messages, message],
        lastUpdated: DateTime.now(),
        status: conv.status,
        negotiationContext: conv.negotiationContext,
      );
      
      conversations[index] = updatedConv;
      await saveConversations(conversations);
    }
  }

  static Future<void> deleteConversation(String id) async {
    final conversations = await loadConversations();
    conversations.removeWhere((c) => c.id == id);
    await saveConversations(conversations);
  }
}
