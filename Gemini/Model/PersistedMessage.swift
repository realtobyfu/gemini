//
//  PersistedMessage.swift
//  Gemini
//
//  Created by Tobias Fu on 11/29/25.
//

import SwiftData
import Foundation

@Model
final class PersistedMessage {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var senderRaw: String
    var statusRaw: String
    
    var textConent: String?
    var imageURL: String?
    
    init(from message: ChatMessage) {
        self.id = message.id
        self.timestamp = message.timestamp
        self.senderRaw = message.sender.rawValue
        self.statusRaw = message.status.rawValue
        
        switch message.content {
        case .text(let text):
            self.textConent = text
        case .image(let url):
            self.imageURL = url
        }
    }
    
    
    // Convert back to Domain Model for the UI
    func toDomain() -> ChatMessage {
        let sender = Sender(rawValue: senderRaw) ?? .user
        let status = MessageStatus(rawValue: statusRaw) ?? .sent
        
        let content: MessageType
        
        if let text = textConent {
            content = .text(text)
        } else if let url = imageURL {
            content = .image(url: url)
        } else {
            content = .text("Unknown content")
        }
        
        return ChatMessage(
            id: id, timestamp: timestamp, sender: sender, content: content, status: status
        )
    }
}
