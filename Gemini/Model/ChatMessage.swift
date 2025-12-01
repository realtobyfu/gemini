//
//  ChatMessage.swift
//  Gemini
//
//  Created by Tobias Fu on 11/29/25.
//
import Foundation

enum MessageType: Codable {
    case text(String)
    case image(url: String)
}

enum Sender: String, Codable {
    case user
    case system
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case failed
    case received
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let sender: Sender
    var content: MessageType
    let status: MessageStatus
    
    var text: String {
        switch content {
        case .text(let text):
            return text
        case .image:
            return "[Image]"
        }
    }

}
