# Tech.AI

An iOS chatbot app built with SwiftUI that uses the OpenAI API to answer Computer Science questions. Includes voice-to-text input via Apple's Speech framework.

## Features

- **AI Chat** — Send messages and receive responses powered by OpenAI's GPT-4.1 model.
- **Voice Input** — Tap the microphone button to dictate questions using speech recognition.
- **Conversation History** — The full chat context is sent with each request for coherent multi-turn conversations.
- **Clear Chat** — Reset the conversation at any time.

## Requirements

- Xcode 16+
- iOS 17+
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

## Project Structure

```
Tech.AI/
├── Tech_AIApp.swift          # App entry point
├── ContentView.swift         # Main chat UI, voice input, and API calls
├── AppConfig.swift           # Reads the API key from Secrets.plist
├── Secrets.plist             # Your API key (git-ignored)
├── Secrets.plist.example     # Template for the Secrets file
└── Assets.xcassets           # App assets
```

## Permissions

When running on a device, the app will request:

- **Speech Recognition** — Required for voice-to-text input.
- **Microphone Access** — Required to capture audio for speech recognition.

## Notes

- `Secrets.plist` is listed in `.gitignore` to prevent accidentally committing your API key.
- The app uses the `gpt-4.1` model. You can change the model in `ContentView.swift` inside the `fetchAIResponse()` function.
