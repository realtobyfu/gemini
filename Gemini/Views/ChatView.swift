//
//  ChatView.swift
//  Gemini
//
//  Created by Tobias Fu on 11/30/25.
//

import Foundation
import SwiftUI

struct ChatView: View {
    @State var viewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    
                    .onChange(of: viewModel.messages.count) {
                        // Scroll to bottom on new message
                        if let last = viewModel.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Scroll to bottom on streaming text update
                    .onChange(of: viewModel.messages.last?.text) {
                         if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                    
                }
                
                HStack {
                    TextField("Ask Gemini...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .disabled(viewModel.isStreaming)

                    Button {
                        let t = inputText
                        inputText = ""
                        Task { await viewModel.sendMessage(t)}
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(viewModel.isStreaming ? .gray: .blue)
                    }
                    .disabled(inputText.isEmpty || viewModel.isStreaming)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .navigationTitle("Gemini")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}

struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }
            
            if message.sender == .system && message.text.isEmpty {
                ProgressView()
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text(LocalizedStringKey(formattedText(message.text)))
                    .padding()
                    .background(message.sender == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(message.sender == .user ? .white : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            if message.sender == .system { Spacer() }
        }
        .padding(.horizontal, 15)
    }
    
    private func formattedText(_ text: String) -> String {
        // Replace "* " with "• " for bullet points
        // Handle start of string
        var formatted = text
        if formatted.hasPrefix("* ") {
            formatted = "• " + formatted.dropFirst(2)
        }
        // Handle newlines
        formatted = formatted.replacingOccurrences(of: "\n* ", with: "\n• ")
        return formatted
    }
}


#Preview {
    let userMessage = ChatMessage(id: UUID(), timestamp: Date(), sender:.user, content: .text("Hi there!"), status: .received)
    let aiMessage = ChatMessage(id: UUID(), timestamp: Date(), sender: .system, content: .text("Hey, what's up?"), status: .received)

    
    VStack {
        MessageBubble(message: userMessage)
        MessageBubble(message: aiMessage)
    }
}
