//
//  MessageBubbleView.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 25/07/25.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        if message.isThinking {
            ThinkingBubbleView()
        } else {
            TextBubbleView(message: message)
        }
    }
}

struct ThinkingBubbleView: View {
    var body: some View {
        HStack(alignment: .bottom) {
            TypingBubbleView()
            Spacer()
        }
        .padding(.horizontal)
        .transition(.opacity)
    }
}

struct TextBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(10)
                .foregroundColor(.white)
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.8))
                .cornerRadius(12)
                .frame(
                    maxWidth: 400,
                    alignment: message.isUser ? .trailing : .leading
                )
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

