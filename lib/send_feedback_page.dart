// lib/send_feedback_page.dart

import 'package:flutter/material.dart';
import 'services/profile_service.dart';

class SendFeedbackPage extends StatefulWidget {
  final String token;
  
  const SendFeedbackPage({
    required this.token,
    Key? key,
  }) : super(key: key);

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final String feedback = _feedbackController.text.trim();
    
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ProfileService(token: widget.token);
      final success = await profileService.sendFeedback(feedback);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          // Return to previous screen with success flag
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send feedback'))
          );
        }
      }
    } catch (e) {
      print('Error sending feedback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sending feedback'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F2EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Send Feedback",
          style: TextStyle(
            fontFamily: 'Archivo',
            fontSize: 25,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02 * 25,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "We appreciate your feedback",
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD55F5F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please share your thoughts, suggestions, or report any issues you've encountered.",
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF9F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 10,
                    style: const TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter your feedback here...",
                      hintStyle: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD55F5F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Submit Feedback",
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
