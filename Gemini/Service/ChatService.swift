//
//  ChatService.swift
//  Gemini
//
//  Created by Tobias Fu on 11/29/25.
//

import Foundation

protocol ChatService: Sendable {
    func streamResponse(_ text: String) -> AsyncThrowingStream<String, Error>
}

struct MockChatService: ChatService {
    func streamResponse(_ text: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            
                let response = "Hi I am Gemini, written in Swift, ask me about anything."
                
                for char in response {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }
}
