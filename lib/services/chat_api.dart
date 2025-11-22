import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatApi {
  final http.Client client;
  final String apiKey;
  ChatApi(this.client, this.apiKey);

  Future<String> reply(String user, List<Map<String, String>> history) async {
    final res = await client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": "Hello $user"},
          ...history
        ]
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(res.body);
      return decoded['choices'][0]['message']['content'];
    }
    throw Exception('openai_failed_${res.statusCode}');
  }
}
