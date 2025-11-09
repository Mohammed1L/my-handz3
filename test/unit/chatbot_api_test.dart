import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:senior_project/services/chat_api.dart';

void main() {
  test('ChatApi returns message on 200', () async {
    final client = MockClient((req) async {
      return http.Response(jsonEncode({
        "choices": [
          {"message": {"content": "Hi!"}}
        ]
      }), 200);
    });
    final api = ChatApi(client, 'FAKE');
    final text = await api.reply('User', [
      {"role": "user", "content": "hello"}
    ]);
    expect(text, 'Hi!');
  });

  test('ChatApi throws on non-200', () async {
    final client = MockClient((_) async => http.Response('err', 500));
    final api = ChatApi(client, 'FAKE');
    expect(
          () => api.reply('User', []),
      throwsA(isA<Exception>()),
    );
  });
}
