//
//  MessageBubble.swift
//  Tech.AI
//
//  Renders a single chat message. While a message is streaming it shows
//  animated "thinking" dots before the first token, then a blinking
//  caret appended to the growing text.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            Group {
                if message.isStreaming && message.text.isEmpty {
                    TypingDotsView()          // waiting for the first token
                } else {
                    Text(message.text + (message.isStreaming ? " ▍" : ""))
                }
            }
            .padding()
            .background(message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            .cornerRadius(8)

            if !message.isUser {
                Spacer()
            }
        }
    }
}

// Three dots that pulse in sequence, shown before the first token arrives.
struct TypingDotsView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 7, height: 7)
                    .foregroundStyle(.secondary)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubble(message: ChatMessage(text: "What is Big-O notation?", isUser: true))
        MessageBubble(message: ChatMessage(text: "Big-O describes how runtime grows", isUser: false, isStreaming: true))
        MessageBubble(message: ChatMessage(text: "", isUser: false, isStreaming: true))
    }
    .padding()
}
