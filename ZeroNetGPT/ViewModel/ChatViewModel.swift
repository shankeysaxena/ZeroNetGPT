//
//  ChatViewModel.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 25/07/25.
//

import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var fileProcessingState: FileProcessingState = .idle
    @Published var isGenerating = false
    
    private let documentProcessor: DocumentProcessor
    
    var isFileSelected: Bool {
        if case .ready = fileProcessingState {
            return true
        }
        return false
    }
    
    init() {
        self.documentProcessor = DocumentProcessor()
        setupInitialMessage()
        bindToDocumentProcessor()
    }
    
    private func setupInitialMessage() {
        messages = [
            ChatMessage(
                isUser: false,
                isThinking: false,
                text: "Hello! Upload a file and I'll help you analyze it. I can answer questions about documents of type pdf or txt"
            )
        ]
    }
    
    private func bindToDocumentProcessor() {
        documentProcessor
            .$fileProcessingState
            .receive(on: DispatchQueue.main)
            .assign(to: &$fileProcessingState)
    }
    
    func pickFile() {
        documentProcessor.pickFile()
    }
    
    func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        return documentProcessor.handleDrop(providers: providers)
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty, !isGenerating, isFileSelected else {
            return
        }
        
        isGenerating = true

        let userMessage = ChatMessage(isUser: true, isThinking: false, text: text)
        messages.append(userMessage)
        
        var assistantMessage = ChatMessage(isUser: false, isThinking: true, text: "")
        messages.append(assistantMessage)
        
        do {
            try await streamAssistantResponse(&assistantMessage, for: text)
        } catch {
            await handleMessageError(error)
        }
        
        isGenerating = false
    }
    
    private func streamAssistantResponse(
        _ assistantMessage: inout ChatMessage,
        for prompt: String
    ) async throws {
        let messageIndex = messages.count - 1
        let stream = try await documentProcessor.streamResponse(for: prompt)
        
        for try await chunk in stream {
            if assistantMessage.text.isEmpty {
                assistantMessage.isThinking = false
            }
            assistantMessage.text += chunk.text
            messages[messageIndex] = assistantMessage
        }
    }
    
    private func handleMessageError(_ error: Error) async {
        let errorMessage = ChatMessage(
            isUser: false,
            isThinking: false,
            text: "Received Error: \(error.localizedDescription)"
        )
        messages.append(errorMessage)
    }
}
