//
//  ChatInputView.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 25/07/25.
//

import SwiftUI

struct ChatInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var inputText = ""
    
    private var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.isGenerating &&
        viewModel.isFileSelected
    }
    
    private var isTextFieldDisabled: Bool {
        return viewModel.isGenerating || !viewModel.isFileSelected
    }
    
    var body: some View {
        HStack {
            TextField("Type your question...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTextFieldDisabled ? Color.gray : Color.blue, lineWidth: 0.5)
                )
                .disabled(isTextFieldDisabled)
                .onSubmit {
                    sendMessageIfPossible()
                }
            
            SendButton(
                canSend: canSendMessage,
                action: sendMessageIfPossible
            )
        }
        .padding()
    }
    
    private func sendMessageIfPossible() {
        guard canSendMessage else {
            return
        }
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        Task {
            await viewModel.sendMessage(messageText)
        }
    }
}

struct SendButton: View {
    let canSend: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(canSend ? Color.blue : Color.gray)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
    }
}
