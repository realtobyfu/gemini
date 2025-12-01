//
//  GeminiAppApp.swift
//  GeminiApp
//
//  Created by Tobias Fu on 11/28/25.
//

import SwiftUI
import SwiftData

@main
struct GeminiApp: App {
    let container: ModelContainer
    @State private var viewModel: ChatViewModel
    
    init() {
        do {
            container = try ModelContainer(for: PersistedMessage.self)
        } catch {
            fatalError("Failed to init DB")
        }
        
        
        let service = BackendChatService()
        let repository = ChatRepository(service: service, container: container)
        viewModel = ChatViewModel(repository: repository)
    }
    
    var body: some Scene {
        WindowGroup {
            ChatView(viewModel: viewModel)
        }
        .modelContainer(container)
    }
}
