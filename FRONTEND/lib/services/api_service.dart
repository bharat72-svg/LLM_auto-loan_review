
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

const String API_URL = 'http://127.0.0.1:8000'; // UPDATE YOUR BACKEND URL

class ApiService {
  static Future<String> uploadFile(Uint8List bytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$API_URL/ocr'));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      var response = await request.send();
      
      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      }
      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeContract(String text, String vin) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text, 'vin': vin}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Analysis failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Analysis error: $e');
    }
  }

  static Future<String> getNegotiationAdvice(String contractData, String userQuery) async {
    // Simulated chatbot response
    await Future.delayed(const Duration(seconds: 1));
    return "Based on your contract analysis, I suggest:\n\n"
        "1) Negotiate the interest rate - Current rates may be above market average\n"
        "2) Request waiver or reduction of late payment fees\n"
        "3) Ask for higher mileage allowance if needed\n"
        "4) Clarify early termination conditions\n\n"
        "Would you like specific advice on any clause?";
  }
}
