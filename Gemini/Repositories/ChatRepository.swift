//
//  ChatRepository.swift
//  Gemini
//
//  Created by Tobias Fu on 11/30/25.
//

import Foundation
import SwiftData

// The Repository

// Swift Data — because actors run on background threads, we cannot use the Main Context (UI Database)
actor ChatRepository {
    private let service: ChatService
    private let modelContainer: ModelContainer
    private let backgroundContext: ModelContext
    
    init(service: ChatService, container: ModelContainer) {
        self.service = service
        self.modelContainer = container
        self.backgroundContext = ModelContext(container)
    }
    
    //
    func save(_ message: ChatMessage) {
        let persisted = PersistedMessage(from: message)
        backgroundContext.insert(persisted)
        try? backgroundContext.save()
    }
    
    func fetchHistory() -> [ChatMessage] {
        let descriptor = FetchDescriptor<PersistedMessage>(sortBy: [SortDescriptor(\.timestamp)])
        let results = (try? backgroundContext.fetch(descriptor)) ?? []
        return results.map { $0.toDomain() }
    }
    
    func sendAndStream(_ text: String) async -> AsyncThrowingStream<String, Error> {
        return await service.streamResponse(text)
    }
    
    func clearHistory() {
        try? backgroundContext.delete(model: PersistedMessage.self)
        try? backgroundContext.save()
    }
    
    func deleteMessages(from date: Date) {
        let descriptor = FetchDescriptor<PersistedMessage>(
            predicate: #Predicate { $0.timestamp >= date }
        )
        if let messages = try? backgroundContext.fetch(descriptor) {
            for message in messages {
                backgroundContext.delete(message)
            }
            try? backgroundContext.save()
        }
    }
}
