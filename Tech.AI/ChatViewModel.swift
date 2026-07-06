//
//  ChatViewModel.swift
//  Tech.AI
//
//  Observable state for the chat screen. Owns the message list and
//  conversation history, and consumes the streaming token feed from
//  the networking layer. Uses async/await + Observation — no Combine.
//

import Foundation
import Observation

private let systemPrompt: [String: String] = [
    "role": "system",
    "content": "You are a highly intelligent assistant and tutor that specializes in Computer Science."
]

@Observable
@MainActor
final class ChatViewModel {

    var messages: [ChatMessage] = []
    var inputText = ""
    var isStreaming = false

    // Full conversation sent to the model. Readable for tests, only
    // mutated internally.
    private(set) var chatHistory: [[String: String]] = [systemPrompt]

    private let service: AIStreaming

    init(service: AIStreaming = OpenAIService()) {
        self.service = service
    }

    // Sends the current input and streams the assistant reply in place.
    func sendMessage() async {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isStreaming else { return }

        messages.append(ChatMessage(text: prompt, isUser: true))
        chatHistory.append(["role": "user", "content": prompt])
        inputText = ""

        // Insert an empty assistant message we will grow token-by-token.
        let assistantID = UUID()
        messages.append(ChatMessage(id: assistantID, text: "", isUser: false, isStreaming: true))
        isStreaming = true

        let historySnapshot = chatHistory
        var completedSuccessfully = false

        do {
            for try await delta in service.streamAIResponse(history: historySnapshot) {
                if let index = messages.firstIndex(where: { $0.id == assistantID }) {
                    messages[index].text += delta
                }
            }
            completedSuccessfully = true
        } catch {
            if let index = messages.firstIndex(where: { $0.id == assistantID }) {
                messages[index].text = "Error: \(error.localizedDescription)"
            }
        }

        if let index = messages.firstIndex(where: { $0.id == assistantID }) {
            messages[index].isStreaming = false
        }
        isStreaming = false

        if completedSuccessfully,
           let assistantText = messages.first(where: { $0.id == assistantID })?.text {
            chatHistory.append(["role": "assistant", "content": assistantText])
        }
    }

    // Clears the conversation and resets history to just the system prompt.
    func clearChat() {
        guard !isStreaming else { return }
        messages = []
        chatHistory = [systemPrompt]
    }
}
