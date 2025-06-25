import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ai_stylist_camera_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIStylistPage extends StatefulWidget {
  @override
  _AIStylistPageState createState() => _AIStylistPageState();
}

class _AIStylistPageState extends State<AIStylistPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> chatHistory = [];
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      chatHistory.add({'role': 'user', 'text': message});
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': message,
          'user_id': _userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data['answer'];
        setState(() {
          chatHistory.add({'role': 'bot', 'text': botReply});
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      setState(() {
        chatHistory.add({
          'role': 'bot',
          'text': 'Sorry, something went wrong. Please try again.'
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'AI Stylist',
          style: TextStyle(
            fontFamily: 'Archivo',
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/ai_stylist_screen_background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
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
                            CircleAvatar(child: Icon(Icons.smart_toy, color: Color(0xFFD55F5F)), backgroundColor: Colors.white),
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
                          color: Colors.white, // CSS background: rgb(FFFFFF''),
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
                          icon: Icon(Icons.camera_alt_outlined, color: Color(0xFFD55F5F)),
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.send, color: Color(0xFFD55F5F)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, String> message, String fontFamily) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFD55F5F) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
} 