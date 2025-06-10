# snapfit

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AI Stylist Chatbot Integration

### Backend Setup
1. Install Python dependencies:
   ```bash
   pip install flask numpy sentence-transformers scikit-learn openai
   ```
2. Set your OpenAI API key as an environment variable:
   ```bash
   export OPENAI_API_KEY=your_openai_api_key_here  # Linux/macOS
   set OPENAI_API_KEY=your_openai_api_key_here     # Windows
   ```
3. Start the backend server:
   ```bash
   python backend/app.py
   ```
   The backend will run on `http://localhost:5000` by default.

### Flutter App Setup
1. In `lib/ai_stylist_page.dart`, set the backend URL in the `sendMessage` function:
   ```dart
   Uri.parse('http://YOUR_BACKEND_IP:5000/chat'),
   ```
   Replace `YOUR_BACKEND_IP` with your backend server's IP address or `localhost` if running on the same machine.
2. Add the `http` package to your `pubspec.yaml` (already included):
   ```yaml
   dependencies:
     http: ^0.14.0
   ```
3. Run your Flutter app:
   ```bash
   flutter pub get
   flutter run
   ```

### Notes
- Ensure your backend is accessible from your device/emulator. If running on a physical device, use your computer's local IP address instead of `localhost`.
- The chatbot uses retrieval-augmented generation (RAG) with OpenAI GPT for fashion-aware responses.
