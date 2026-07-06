# Tech.AI

An iOS chatbot app built with SwiftUI that uses the OpenAI API to answer Computer Science questions. Responses **stream in token-by-token** for a live, ChatGPT-style experience, the interface is styled with Apple's **Liquid Glass** design system, and questions can be dictated with voice-to-text via Apple's Speech framework.

## Features

- **Streaming AI Chat** — Responses render token-by-token as the model generates them, using OpenAI's `gpt-4.1` model over Server-Sent Events (SSE).
- **Live Typing Indicators** — Animated dots appear while waiting for the first token, followed by a blinking caret on the message as it streams.
- **Auto-Scroll** — The conversation keeps the newest content in view while a response streams.
- **Liquid Glass UI** — The input field, voice button, and Clear Chat control use Liquid Glass, grouped in a `GlassEffectContainer`, with a graceful Material fallback on older systems.
- **Voice Input** — Tap the microphone button to dictate questions using speech recognition; it pulses while recording.
- **Conversation History** — The full chat context is sent with each request for coherent multi-turn conversations.
- **Clear Chat** — Reset the conversation any time from the toolbar.

## Requirements

- Xcode 26+ (for the Liquid Glass APIs)
- iOS 18.2+ deployment target — Liquid Glass styling is used on iOS 26+, with an automatic `.ultraThinMaterial` / bordered-button fallback on earlier versions
- An [OpenAI API Key](https://platform.openai.com/api-keys)

## Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/<your-username>/Tech.AI.git
   cd Tech.AI
   ```

2. **Create your Secrets file**

   The API key is stored in a property list that is excluded from version control. A template is provided:

   ```bash
   cp Tech.AI/Secrets.plist.example Tech.AI/Secrets.plist
   ```

3. **Add your OpenAI API key**

   Open `Tech.AI/Secrets.plist` and replace `REPLACE_WITH_YOUR_API_KEY` with your actual OpenAI API key:

   ```xml
   <key>API_KEY</key>
   <string>sk-your-key-here</string>
   ```

4. **Open the project in Xcode**

   ```bash
   open Tech.AI.xcodeproj
   ```

5. **Build and run**

   Select a simulator or connected device and press **Cmd + R**.

## Architecture

The app follows a layered, MVVM-style split so networking and state stay out of the view and remain testable:

```
ContentView  ──▶  ChatViewModel  ──▶  OpenAIService
 (SwiftUI)         (@Observable)       (SSE client)
```

- **`OpenAIService`** — Networking only. Streams assistant text deltas as an `AsyncThrowingStream<String, Error>` using `URLSession.bytes(for:)` and SSE parsing. Hidden behind an `AIStreaming` protocol so tests can inject a mock.
- **`ChatViewModel`** — An `@Observable`, `@MainActor` class that owns the messages, input text, and conversation history. It consumes the token stream and appends each delta to the in-flight assistant message. Uses Swift async/await (no Combine).
- **`ContentView`** — Pure rendering and user input: the message list with auto-scroll, the Liquid Glass input bar, and the toolbar.

## Project Structure

```
Tech.AI/
├── Tech_AIApp.swift          # App entry point
├── ContentView.swift         # Chat screen: message list, input bar, voice, toolbar
├── ChatViewModel.swift       # @Observable state; streaming send loop & history
├── OpenAIService.swift       # SSE streaming client + AIStreaming protocol
├── ChatMessage.swift         # Chat message model (mutable text + isStreaming)
├── MessageBubble.swift       # Message bubble, streaming caret, and typing dots
├── LiquidGlassStyle.swift    # Liquid Glass helpers with Material fallback
├── AppConfig.swift           # Reads the API key from Secrets.plist
├── Secrets.plist             # Your API key (git-ignored)
├── Secrets.plist.example     # Template for the Secrets file
└── Assets.xcassets           # App assets

Tech.AITests/                 # Swift Testing unit tests
Tech.AIUITests/               # XCUITest UI tests
```

## Testing

- **Unit tests** (`Tech.AITests`, Swift Testing framework) cover SSE line parsing, token accumulation, the error path, and conversation-history integrity — all against a mock streaming service, so no network or API key is required.
- **UI tests** (`Tech.AIUITests`, XCUITest) cover sending a message, the Send button's enabled/disabled state, and Clear Chat.

Run all tests with **Cmd + U** in Xcode.

## Permissions

When running on a device, the app will request:

- **Speech Recognition** — Required for voice-to-text input.
- **Microphone Access** — Required to capture audio for speech recognition.

## Notes

- `Secrets.plist` is listed in `.gitignore` to prevent accidentally committing your API key.
- The app uses the `gpt-4.1` model. You can change the model in `OpenAIService.swift` inside the `makeRequest(history:)` function.
