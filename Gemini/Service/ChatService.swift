//
//  ChatService.swift
//  Gemini
//
//  Created by Tobias Fu on 11/29/25.
//

import Foundation
import FoundationModels


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

struct SimpleFoundationChatService: ChatService {
    private let session: LanguageModelSession

    init(instructions: String? = nil) {
        if let instr = instructions {
            session = LanguageModelSession(instructions: instr)
        } else {
            session = LanguageModelSession()
        }
    }

    func streamResponse(_ text: String) -> AsyncThrowingStream<String, Error> {
        let model = SystemLanguageModel.default
        
        guard model.isAvailable else {
            return AsyncThrowingStream { continuation in
                continuation.yield("⚠️ Foundation model not available on this device.")
                continuation.finish()
            }
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = session.streamResponse(to: text)
                    for try await partial in stream {
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

struct BackendChatService: ChatService {
    func streamResponse(_ text: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                let url = URL(string: "http://127.0.0.1:8000/chat")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body = ["text": text]
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)
                
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: URLError(.badServerResponse))
                        return
                    }
                    
                    // Stream chunks as they arrive
                    for try await byte in bytes {
                        if let char = String(bytes: [byte], encoding: .utf8) {
                            continuation.yield(char)
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
