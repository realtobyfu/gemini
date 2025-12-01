//
//  ChatViewModel.swift
//  Gemini
//
//  Created by Tobias Fu on 11/30/25.
//

import Foundation
import SwiftData

// Performance Optimization: we do not save the streaming AI response to the database every 0.05 secs. We keep it in RAM until it finishes, then save it.
@MainActor
@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var isStreaming: Bool = false
    
    private let repository: ChatRepository
    
    init(repository: ChatRepository) {
        self.repository = repository
        loadHistory()
    }
    
    func loadHistory() {
        Task {
            self.messages = await repository.fetchHistory()
        }
    }
    
    func sendMessage(_ text: String) async {
        let userMsg = ChatMessage(
            id: UUID(), timestamp: Date(), sender: .user, content: .text(text), status: .sending
        )
        var aiContent = ""
        messages.append(userMsg)
        await repository.save(userMsg)
                
        let aiMsg = ChatMessage(id: UUID(), timestamp: Date(), sender: .system, content: .text(""), status: .sending)
        
        messages.append(aiMsg)
        isStreaming = true
        
        do {
            let stream = await repository.sendAndStream(text)
            for try await token in stream {
                aiContent += token
                // ai message is the last one we just added
                // messages.firstIndex(where:{$0.id == aiMsg.id}) is O(n) time
                if !messages.isEmpty {
                    messages[messages.count - 1].content = .text(aiContent)
                }
            }
            
            if let lastMessage = messages.last {
                await repository.save(lastMessage)
            }
        } catch {
            print("Stream failed")
        }
        
        isStreaming = false
    }
    
    func clearHistory() {
        Task {
            await repository.clearHistory()
            self.messages = []
        }
    }
}
