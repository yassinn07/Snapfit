import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ai_stylist_camera_screen.dart';

class AIStylistPage extends StatefulWidget {
  @override
  _AIStylistPageState createState() => _AIStylistPageState();
}

class _AIStylistPageState extends State<AIStylistPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> chatHistory = [];
  bool _isLoading = false;

  Future<void> sendMessage(String message) async {
    setState(() {
      chatHistory.add({'role': 'user', 'text': message});
      _isLoading = true;
    });
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': message}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final botReply = data['answer'];
      setState(() {
        chatHistory.add({'role': 'bot', 'text': botReply});
        _isLoading = false;
      });
    } else {
      setState(() {
        chatHistory.add({'role': 'bot', 'text': 'Sorry, something went wrong.'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';
    return Scaffold(
      backgroundColor: Color(0xFFF6F2EF),
      appBar: AppBar(
        backgroundColor: Color(0xFFF6F2EF),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'AI Stylist',
          style: TextStyle(
            fontFamily: defaultFontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              reverse: false,
              itemCount: chatHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == chatHistory.length) {
                  return Row(
                    children: [
                      CircleAvatar(child: Icon(Icons.smart_toy, color: Colors.white), backgroundColor: Color(0xFFD55F5F)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  );
                }
                return _buildMessage(chatHistory[index], defaultFontFamily);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFD55F5F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AIStylistCameraScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(fontFamily: defaultFontFamily, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Ask me about fashion!',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFD55F5F),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final msg = _controller.text;
                      if (msg.isNotEmpty && !_isLoading) {
                        sendMessage(msg);
                        _controller.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, String> entry, String fontFamily) {
    bool isUser = entry['role'] == 'user';
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: CircleAvatar(
                backgroundColor: Color(0xFFD55F5F),
                child: Icon(Icons.smart_toy, color: Colors.white),
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.pink[100] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                entry['text'] ?? '',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: CircleAvatar(
                backgroundColor: Colors.pink[100],
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
} 