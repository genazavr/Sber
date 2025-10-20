import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/leaf_background.dart';


const String API_ENDPOINT =
    'https://api.intelligence.io.solutions/api/v1/chat/completions';
const String API_KEY = 'io-v2-eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvd25lciI6IjEzYTk1NjZlLWE5OWQtNDlmYy04YzJjLTE3MDFiYWY4YjYwMCIsImV4cCI6NDkxNDQyNzEzMH0.kgDeNQVg_p26eJBtdRb73gB1VFENY1y_oAH4mb0bfj3yQc_RCgpmQNi2mhWG7RHADkIfxewLUoU8Vv62Zx72YQ'; // 🔑 добавь ключ
const String MODEL_ID = 'openai/gpt-oss-120b';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;
  String _selectedCharacter = 'Копатыч';

  String get _systemPrompt {
    switch (_selectedCharacter) {
      case 'Ёжик':
        return '''
Ты — Ёжик 🦔. Застенчивый, вежливый и доброжелательный.
Отвечай мягко, дружелюбно и по-детски понятно. Любишь природу и уют.
Пиши по-русски.
делай не большые ответы
''';
      case 'Лосяш':
        return '''
Ты — Лосяш 🦌. Учёный, но добрый и весёлый. Объясняй просто, с примерами и немного юмора.
Пиши по-русски.
делай не большые ответы
''';
      default:
        return '''
Ты — Копатыч 🐻. Добродушный фермер, любишь труд и природу. Отвечай с теплом и простотой.
Пиши по-русски. Добавляй фразы вроде:
— «Главное — с любовью к земле!»
делай не большые ответы
''';
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _loading = true;
      _controller.clear();
    });

    final payloadMessages = <Map<String, String>>[
      {"role": "system", "content": _systemPrompt},
      ..._messages.map((m) => {"role": m.role, "content": m.content}),
    ];

    final payload = {
      "model": MODEL_ID,
      "messages": payloadMessages,
      "max_tokens": 512,
      "temperature": 0.7,
    };

    try {
      final resp = await http.post(
        Uri.parse(API_ENDPOINT),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $API_KEY',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        String? reply;

        if (data['choices'] != null) {
          final first = (data['choices'] as List).first;
          reply = first['message']?['content'] ??
              first['text'] ??
              data['content']?.toString();
        }

        reply ??= 'Эх, задумался я... но ответ не придумал 😅';

        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: reply!));
        });

        await Future.delayed(const Duration(milliseconds: 50));
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            content: 'Упс... ошибка сервера (${resp.statusCode}) 😔',
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: 'Связь с сервером пропала 😢\n$e',
        ));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearHistory() => setState(() => _messages.clear());

  Widget _buildCharacterSelector() {
    final characters = [
      {'name': 'Копатыч', 'emoji': '🐻'},
      {'name': 'Ёжик', 'emoji': '🦔'},
      {'name': 'Лосяш', 'emoji': '🦌'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: characters.map((ch) {
        final selected = _selectedCharacter == ch['name'];
        return GestureDetector(
          onTap: () => setState(() {
            _selectedCharacter = ch['name']!;
            _messages.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? Colors.green.shade300 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(ch['emoji']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  ch['name']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    final bubbleColor =
    isUser ? Colors.green.shade100 : Colors.white.withOpacity(0.9);
    final textColor = isUser ? Colors.black87 : Colors.brown.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.green.shade400,
              child: Text(
                _selectedCharacter.characters.first,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: SelectableText(
                msg.content,
                style: TextStyle(fontSize: 16, color: textColor, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(

        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildCharacterSelector(),
              const SizedBox(height: 10),


              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) =>
                      _buildMessageBubble(_messages[i]),
                ),
              ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(color: Colors.green),
                ),


              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Напиши $_selectedCharacter...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.send),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _messages.isEmpty ? null : _clearHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade200,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  _ChatMessage({required this.role, required this.content});
}
