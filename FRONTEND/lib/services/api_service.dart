
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

const String API_URL = 'http://127.0.0.1:8000'; // URL

class ApiService {
  // Step 1: Upload file to /ocr
  static Future<String> uploadFile(Uint8List bytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$API_URL/ocr'));
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseBody);
        return jsonResponse['ocr_text'] ?? '';
      }
      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Step 2: Analyze contract from /analyze (GET, no parameters)
  static Future<Map<String, dynamic>> analyzeContract(String text, String vin) async {
    try {
      // Your backend /analyze is GET with no input - it reads from saved file
      final response = await http.get(
        Uri.parse('$API_URL/analyze'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Analysis failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Analysis error: $e');
    }
  }

  static Future<String> getChatbotResponse(String userMessage, String contractContext) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_message': userMessage,
          'contract_context': contractContext,
        }),
      ).timeout(
        const Duration(seconds: 30),  // ✅ Inline timeout
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['response'] ?? 'I couldn\'t process that. Please try again.';
      }
      throw Exception('Chat failed: ${response.statusCode}');
    } catch (e) {
      // Fallback to local responses if backend fails
      return _getFallbackResponse(userMessage);
    }
  }

  static String _getFallbackResponse(String query) {
    String lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('interest') || lowerQuery.contains('rate')) {
      return "💰 **Interest Rate Negotiation**\n\n"
          "To negotiate better rates:\n"
          "• Research current market rates (5-7% typical)\n"
          "• Highlight your credit score if strong\n"
          "• Mention competing offers\n"
          "• Request 0.5-1% reduction\n\n"
          "Would you like specific talking points?";
    }
    
    if (lowerQuery.contains('fee') || lowerQuery.contains('charge') || lowerQuery.contains('cost')) {
      return "💵 **Fee Reduction Strategy**\n\n"
          "Key areas to negotiate:\n"
          "• Processing fee waiver (~₹12,000+)\n"
          "• Lower late payment penalties\n"
          "• Extended grace periods\n"
          "• Cap on cumulative fees\n\n"
          "Typical savings: ₹5,000-15,000";
    }
    
    if (lowerQuery.contains('terminate') || lowerQuery.contains('exit') || lowerQuery.contains('end')) {
      return "🚪 **Early Termination Advice**\n\n"
          "Key negotiation points:\n"
          "• Request penalty-free exit after 24 months\n"
          "• Clarify deficit calculation formula\n"
          "• Ask for fixed exit fee vs percentage\n"
          "• Ensure no credit bureau impact\n\n"
          "Need help drafting a request?";
    }
    
    if (lowerQuery.contains('good') || lowerQuery.contains('fair') || lowerQuery.contains('score')) {
      return "📊 **Contract Fairness Assessment**\n\n"
          "I can help you understand:\n"
          "• What your fairness score means\n"
          "• Strengths of your contract\n"
          "• Areas needing improvement\n"
          "• Comparison with industry standards\n\n"
          "What specific aspect concerns you?";
    }
    
    return "🤖 **I'm here to help!**\n\n"
        "I can assist with:\n"
        "• Interest rate negotiation strategies\n"
        "• Fee reduction tactics\n"
        "• Understanding complex clauses\n"
        "• Early termination options\n"
        "• Vehicle valuation insights\n\n"
        "Ask me anything specific about your contract!";
  }

  // ADD THESE TO YOUR EXISTING api_service.dart

/// Send message to dealer (simulated backend)
  static Future<String> sendDealerMessage({
    required String conversationId,
    required String userMessage,
    required Map<String, dynamic> contractContext,
    required Map<String, dynamic> negotiationContext,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/dealer/message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversation_id': conversationId,
          'user_message': userMessage,
          'contract_context': contractContext,
          'negotiation_context': negotiationContext,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['dealer_response'] ?? 'No response';
      }
      throw Exception('Dealer response failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dealer API error: $e');
    }
  }

/// Get AI negotiation guidance in real-time
  static Future<String> getRealtimeNegotiationGuidance({
    required String userMessage,
    required String dealerResponse,
    required Map<String, dynamic> contractContext,
    required Map<String, dynamic> negotiationContext,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/negotiation/guidance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_message': userMessage,
          'dealer_response': dealerResponse,
          'contract_context': contractContext,
          'negotiation_context': negotiationContext,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['ai_guidance'] ?? 'Continue negotiating';
      }
      throw Exception('Guidance failed: ${response.statusCode}');
    } catch (e) {
    // Fallback guidance
      return _getFallbackGuidance(dealerResponse);
    }
  }

  static String _getFallbackGuidance(String dealerResponse) {
    String lower = dealerResponse.toLowerCase();
  
    if (lower.contains('reduce') || lower.contains('lower')) {
      return '✅ Good! Dealer is open to reduction. Push for 10-15% more.';
    }
    if (lower.contains('best') || lower.contains('final')) {
      return '⚠️ Dealer claims "best offer". Counter with competitor pricing.';
    }
    if (lower.contains('manager') || lower.contains('discuss')) {
      return '💡 Positive signal! They\'re considering your request.';
    }
    if (lower.contains('no') || lower.contains('cannot')) {
      return '🔄 Don\'t give up. Ask what they CAN do instead.';
    }
  
    return '💬 Keep the conversation going. Ask specific questions.';
  }


  
}
