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
    @Namespace private var bottomID
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(isStreaming: $viewModel.isStreaming, message: message) { msg in
                                    viewModel.deleteFrom(msg)
                                }
                            }
                            Spacer().frame(height: 1).id(bottomID)
                        }
                        .padding()
                    }
                    
                    .onChange(of: viewModel.messages.count) {
                        // Scroll to bottom on new message
                        withAnimation {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                    
                    // Scroll to bottom on streaming text update
                    .onChange(of: viewModel.messages.last?.text) {
                        // Throttle scroll updates to avoid layout thrashing
                        Task {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                    
                }
                
                HStack {
                    TextField("Ask Gemini...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .disabled(viewModel.isStreaming)

                    Button {
                        if viewModel.isStreaming {
                            viewModel.stopGeneration()
                        } else {
                            let t = inputText
                            inputText = ""
                            viewModel.sendMessage(t)
                        }
                    } label: {
                        Image(systemName: viewModel.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(viewModel.isStreaming ? .red : .blue)
                    }
                    .disabled(inputText.isEmpty && !viewModel.isStreaming)
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
    @Binding var isStreaming: Bool
    let message: ChatMessage
    var deleteAction: ((ChatMessage) -> Void)?
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }
            
            if message.sender == .system && message.text.isEmpty && isStreaming {
                ProgressView()
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Text(LocalizedStringKey(formattedText(message.text)))
                    .padding(14)
                    .background(message.sender == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(message.sender == .user ? .white : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            if message.sender == .system { Spacer() }
        }
        .padding(.horizontal, 8)
        .contextMenu {
            Button(role: .destructive) {
                deleteAction?(message)
            } label: {
                Label("Delete from here", systemImage: "trash")
            }
        }
    }
    
    private func formattedText(_ text: String) -> String {
        // (?m) = multiline mode: ^ and $ work per line
        // ^(\s*)\*  = start of line, capture leading whitespace, then a literal "* "
        let pattern = #"(?m)^(\s*)\* "#
        
        return text.replacingOccurrences(
            of: pattern,
            with: "$1• ",                // keep the same indentation, swap * for •
            options: .regularExpression
        )
    }
}


#Preview {
    @Previewable @State var stream: Bool = false
    let userMessage = ChatMessage(id: UUID(), timestamp: Date(), sender:.user, content: .text("Hi there!"), status: .received)
    let aiMessage = ChatMessage(id: UUID(), timestamp: Date(), sender: .system, content: .text("Hey, what's up?"), status: .received)
    VStack {
        MessageBubble(isStreaming: $stream, message: userMessage)
        MessageBubble(isStreaming: $stream, message: aiMessage)
    }
}
