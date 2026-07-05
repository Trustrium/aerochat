# Antigravity AI - Flutter Clone

A mobile-first Flutter clone of Antigravity with AI chat support. Features beautiful floating bubble animations, customizable AI provider configurations, and chat history persistence.

## Features

- **Antigravity-style UI**: Floating bubble animations with smooth, generative motion
- **Multi-Provider Support**: Connect to OpenAI, Anthropic Claude, Google Gemini, or custom/local endpoints
- **Mobile-First Design**: Optimized for smartphones with a bottom navigation bar
- **Chat History**: Persistent chat sessions with SQLite database
- **Dark/Light Themes**: Toggle between dark and light modes
- **Easy Configuration**: Set up and switch between multiple AI providers

## Screenshots

- **Chat Screen**: Full-screen chat with floating bubble background animations
- **Settings Screen**: Configure multiple AI providers with API keys and custom endpoints
- **History Screen**: Browse past conversations with swipe-to-delete

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode (for emulators/simulators)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd antigravity_clone
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Configuration

1. Open the app and tap **Settings** in the bottom navigation
2. Select an AI provider category:
   - **OpenAI**: For GPT-3.5/GPT-4 models
   - **Anthropic**: For Claude models
   - **Google**: For Gemini models  
   - **Local/Custom**: For Ollama or other custom endpoints
3. Enter your API key and configure the model
4. Enable the provider and save

#### Default Endpoints

- **OpenAI**: `https://api.openai.com`
- **Anthropic**: `https://api.anthropic.com`
- **Google**: `https://generativelanguage.googleapis.com`
- **Local/Ollama**: `http://localhost:11434`

## Architecture

```
lib/
├── config/
│   └── app_config.dart          # Configuration models & SharedPreferences
├── models/
│   └── message.dart             # Message, ChatSession, Provider models
├── services/
│   ├── ai_service.dart          # AI provider API implementations
│   └── database_service.dart    # SQLite persistence
├── screens/
│   ├── chat_screen.dart         # Main chat interface with bubbles
│   ├── settings_screen.dart     # Provider configuration
│   └── history_screen.dart      # Chat history list
└── main.dart                     # App entry point & theming
```

## Key Components

### AI Providers

Supports streaming and standard API calls for:
- OpenAI Chat Completions API
- Anthropic Messages API  
- Google Gemini API
- Ollama/OpenAI-compatible local endpoints

### Floating Bubbles

Custom `FloatingBubble` class with physics-based animation system creating the signature Antigravity effect.

```dart
class FloatingBubble {
  double x, y, size, speed;
  Color color;
}
```

### Chat History

SQLite database with tables for chat sessions and messages, supporting full conversation persistence.

## Dependencies

Core packages:

- `http: ^1.1.0` - HTTP requests to AI APIs
- `shared_preferences: ^2.2.2` - App configuration storage
- `sqflite: ^2.3.0` - SQLite database for chat history
- `provider: ^6.1.1` - State management
- `flutter_staggered_animations: ^1.1.1` - UI animations
- `shimmer: ^3.0.0` - Loading effects
- `bubble: ^1.2.1` - Chat bubble UI

## Customization

### Adding Custom Providers

Edit `lib/config/app_config.dart`:

```dart
enum AIProvider {
  openAI,
  anthropic,
  google,
  local,
  customProvider,  // Add your custom provider
}
```

Then implement in `lib/services/ai_service.dart`:

```dart
Future<String> _sendCustomProviderMessage(
  ProviderConfig provider,
  List<Message> messages,
) async {
  // Your custom implementation
}
```

### Theming

Modify `lib/main.dart` to customize the dark/light themes:

```dart
ThemeData _buildDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      // Custom colors
    ),
  );
}
```

## Platform Support

- [x] Android
- [x] iOS
- [x] Linux
- [x] macOS
- [x] Windows
- [ ] Web (requires CORS handling for AI APIs)

## Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by [Antigravity](https://neal.fun/antigravity/)
- Flutter framework by Google
- Icons by Material Design
