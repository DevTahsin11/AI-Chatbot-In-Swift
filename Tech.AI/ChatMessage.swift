//
//  ChatMessage.swift
//  Tech.AI
//
//  Created by Tahsin Ahmed on 12/20/25
//

import Foundation

// Struct for chat message
struct ChatMessage: Identifiable {
    let id: UUID
    var text: String                // mutable so streamed tokens can append
    let isUser: Bool
    var isStreaming: Bool = false   // true while tokens are still arriving

    init(id: UUID = UUID(), text: String, isUser: Bool, isStreaming: Bool = false) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.isStreaming = isStreaming
    }
}
