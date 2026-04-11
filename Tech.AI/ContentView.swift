//
//  ContentView.swift
//  Tech.AI
//
//  Created by Tahsin Ahmed on 12/20/25
//

import SwiftUI
import Speech
import AVFoundation

// Struct for chat message
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ContentView: View {
    
    // Chat Variables
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    
    // Voice-To-Text Variables
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    // Chat History (to send full conversation)
    @State private var chatHistory: [[String: String]] = [
        ["role": "system", "content": "You are a highly intelligent assistant and tutor that specializes in Computer Science."]
    ]
    
    var body: some View {
        
        VStack {
            
            // Chat messages scroll view
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser { Spacer() }
                            Text(message.text)
                                .padding()
                                .background(message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            if message.isUser == false
                            {
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Input field and send button
            HStack {
                TextField("Ask Anything About Computer Science...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Send")
                    }
                }
                .disabled(inputText.isEmpty || isLoading)
                
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 30))
                        .foregroundColor(isRecording ? .red : .blue)
                }
                .padding(.bottom, 8)
            }
            .padding()
            
            
            Button(action: clearChat) {
                Text("Clear Chat")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.bottom, 8)
        }
    }
    
    // Function To Clear All Messages In Chat
    func clearChat() {
        messages = []
        chatHistory = [
            ["role": "system", "content": "You are a highly intelligent assistant and tutor that specializes in Computer Science."]
        ]
    }

    // Function To Start Recording (Subject To Change)
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization
        {authStatus in
            if authStatus == .authorized
            {
                DispatchQueue.main.async
                {
                    self.isRecording = true
                }
                
                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Audio session error: \(error)")
                }
                
                let inputNode = audioEngine.inputNode
                
                guard let recognitionRequest = recognitionRequest
                else
                {
                    fatalError("Unable to create recognition request")
                }
                recognitionRequest.shouldReportPartialResults = false
                
                self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest)
                {result, error in
                    if let result = result
                    {
                        let spokenText = result.bestTranscription.formattedString
                        print("Recognized: \(spokenText)")
                        DispatchQueue.main.async
                        {
                            self.inputText = spokenText
                            Task {
                                await self.sendMessage()
                            }
                        }
                    }
                    
                    if error != nil || (result?.isFinal ?? false)
                    {
                        self.audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        DispatchQueue.main.async
                        {
                            self.isRecording = false
                        }
                    }
                }
                
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat)
                {buffer, when in
                    self.recognitionRequest?.append(buffer)
                }
                
                self.audioEngine.prepare()
                do {
                    try self.audioEngine.start()
                } catch
                {
                    print("Audio Engine start error: \(error)")
                }
            } else{
                print("Speech recognition authorization denied")
            }
        }
    }

    // Function To Stop Recording
    func stopRecording()
    {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
    }
    
    // Sends the message and calls fetchAIResponse (Subject To Change)
    func sendMessage() async {
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        
        // Add to chat history
        chatHistory.append(["role": "user", "content": inputText])
        
        isLoading = true
        
        do {
            let responseText = try await fetchAIResponse()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                let aiMessage = ChatMessage(text: responseText, isUser: false)
                messages.append(aiMessage)
                
                // Add AI message to chat history
                chatHistory.append(["role": "assistant", "content": responseText])
                
                isLoading = false
                inputText = ""
            }
        } catch {
            DispatchQueue.main.async {
                messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false))
                isLoading = false
            }
        }
    }
    
    // Fetches AI response using async/await (Subject To Change)
    func fetchAIResponse() async throws -> String {
        
        // API Call
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions")
        else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4.1",
            "messages": chatHistory
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Debug print of raw response
        if let rawJSON = String(data: data, encoding: .utf8) {
            print("Raw response: \(rawJSON)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Preview
#Preview {
    ContentView()
}
