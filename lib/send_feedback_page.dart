// lib/send_feedback_page.dart

import 'package:flutter/material.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement feedback submission logic (e.g., API call)
      print('Feedback submitted: ${_feedbackController.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      // Optionally clear the field and navigate back
      _feedbackController.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultFontFamily = 'Archivo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Send Feedback",
          style: TextStyle(
            fontFamily: defaultFontFamily,
            fontSize: 25,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02 * 25,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "We appreciate your feedback! Let us know how we can improve.",
                style: TextStyle(
                  fontFamily: defaultFontFamily,
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _feedbackController,
                maxLines: 8, // Allow multiple lines for feedback
                minLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter your feedback here...",
                  hintStyle: TextStyle(
                    fontFamily: defaultFontFamily,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F1EE).withOpacity(0.5), // Light background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                ),
                style: TextStyle(fontFamily: defaultFontFamily, fontSize: 16, color: Colors.black),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback before submitting.';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50), // Full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Submit Feedback",
                  style: TextStyle(
                    fontFamily: defaultFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
