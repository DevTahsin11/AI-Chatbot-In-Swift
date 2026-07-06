//
//  Tech_AITests.swift
//  Tech.AITests
//
//  Created by Tahsin Ahmed  on 6/6/25.
//

import Testing
@testable import Tech_AI

// A stand-in for OpenAIService that emits a scripted set of deltas
// (or fails), so the view model can be tested without any network.
struct MockStreamingService: AIStreaming {
    let deltas: [String]
    let failure: OpenAIError?

    init(deltas: [String] = [], failure: OpenAIError? = nil) {
        self.deltas = deltas
        self.failure = failure
    }

    func streamAIResponse(history: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            for delta in deltas {
                continuation.yield(delta)
            }
            if let failure {
                continuation.finish(throwing: failure)
            } else {
                continuation.finish()
            }
        }
    }
}

struct Tech_AITests {

    // MARK: SSE line parsing

    @Test func parsesDeltaLine() {
        let line = "data: {\"choices\":[{\"delta\":{\"content\":\"Hi\"}}]}"
        #expect(OpenAIService.parseSSELine(line) == .delta("Hi"))
    }

    @Test func parsesDoneTerminator() {
        #expect(OpenAIService.parseSSELine("data: [DONE]") == .done)
    }

    @Test func ignoresNonContentLines() {
        #expect(OpenAIService.parseSSELine("") == .ignore)
        #expect(OpenAIService.parseSSELine(": keep-alive") == .ignore)
        #expect(OpenAIService.parseSSELine("data: {\"choices\":[{\"delta\":{}}]}") == .ignore)
    }

    // MARK: Delta accumulation

    @Test @MainActor func accumulatesDeltasIntoOneMessage() async {
        let vm = ChatViewModel(service: MockStreamingService(deltas: ["Hel", "lo"]))
        vm.inputText = "hi"
        await vm.sendMessage()

        #expect(vm.messages.last?.text == "Hello")
        #expect(vm.messages.last?.isStreaming == false)
        #expect(vm.isStreaming == false)
    }

    // MARK: Error path

    @Test @MainActor func errorSurfacesInMessageAndResetsState() async {
        let vm = ChatViewModel(service: MockStreamingService(failure: .badStatus(401)))
        vm.inputText = "hi"
        await vm.sendMessage()

        #expect(vm.messages.last?.text.hasPrefix("Error:") == true)
        #expect(vm.messages.last?.isStreaming == false)
        #expect(vm.isStreaming == false)
    }

    // MARK: History integrity

    @Test @MainActor func appendsUserAndAssistantToHistory() async {
        let vm = ChatViewModel(service: MockStreamingService(deltas: ["Hi"]))
        vm.inputText = "hello"
        await vm.sendMessage()

        // system + user + assistant
        #expect(vm.chatHistory.count == 3)
        #expect(vm.chatHistory[1]["role"] == "user")
        #expect(vm.chatHistory[1]["content"] == "hello")
        #expect(vm.chatHistory[2]["role"] == "assistant")
        #expect(vm.chatHistory[2]["content"] == "Hi")
    }

    @Test @MainActor func clearChatResetsToSystemPromptOnly() async {
        let vm = ChatViewModel(service: MockStreamingService(deltas: ["Hi"]))
        vm.inputText = "hello"
        await vm.sendMessage()
        vm.clearChat()

        #expect(vm.messages.isEmpty)
        #expect(vm.chatHistory.count == 1)
        #expect(vm.chatHistory[0]["role"] == "system")
    }
}
