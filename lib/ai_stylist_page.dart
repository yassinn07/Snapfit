import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ai_stylist_camera_screen.dart';
import 'dart:async'; // Added for Timer

class AIStylistPage extends StatefulWidget {
  final int userId;
  final String token;
  const AIStylistPage({required this.userId, required this.token, Key? key}) : super(key: key);

  @override
  _AIStylistPageState createState() => _AIStylistPageState();
}

class _AIStylistPageState extends State<AIStylistPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> chatHistory = [];
  bool _isLoading = false;
  String _animatedBotText = '';
  bool _isAnimating = false;
  String _loadingDots = '.';
  Timer? _loadingTimer;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startLoadingDots() {
    _loadingDots = '.';
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      setState(() {
        if (_loadingDots.length == 3) {
          _loadingDots = '.';
        } else {
          _loadingDots += '.';
        }
      });
      _scrollToBottom();
    });
  }

  void _stopLoadingDots() {
    _loadingTimer?.cancel();
    _loadingDots = '.';
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      chatHistory.add({'role': 'user', 'text': message});
      _isLoading = true;
      _animatedBotText = '';
      _isAnimating = false;
    });
    _scrollToBottom();
    _startLoadingDots();

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': message,
          'user_id': widget.userId.toString(),
        }),
      );

      _stopLoadingDots();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data['answer'];
        await _animateBotReply(botReply);
        setState(() {
          chatHistory.add({'role': 'bot', 'text': botReply});
          _isLoading = false;
          _animatedBotText = '';
          _isAnimating = false;
        });
        _scrollToBottom();
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      _stopLoadingDots();
      setState(() {
        chatHistory.add({
          'role': 'bot',
          'text': 'Sorry, something went wrong. Please try again.'
        });
        _isLoading = false;
        _animatedBotText = '';
        _isAnimating = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _animateBotReply(String reply) async {
    setState(() {
      _animatedBotText = '';
      _isAnimating = true;
    });
    for (int i = 0; i < reply.length; i++) {
      await Future.delayed(const Duration(milliseconds: 18));
      setState(() {
        _animatedBotText = reply.substring(0, i + 1);
      });
      _scrollToBottom();
    }
    setState(() {
      _isAnimating = false;
    });
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
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    reverse: false,
                    itemCount: chatHistory.length + ((_isLoading || _isAnimating) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if ((_isLoading || _isAnimating) && index == chatHistory.length) {
                        return _buildAnimatedBotMessage(_animatedBotText, defaultFontFamily);
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
                                builder: (context) => AIStylistCameraScreen(
                                  userId: widget.userId,
                                  token: widget.token,
                                ),
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

  Widget _buildAnimatedBotMessage(String text, String fontFamily) {
    if (_isLoading && !_isAnimating) {
      // Show animated dots while waiting for LLM response
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
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
            _loadingDots,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
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
          text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
} 