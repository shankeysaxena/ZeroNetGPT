//
//  ChatListView.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 25/07/25.
//

import SwiftUI

struct ChatListView: View {
    let messages: [ChatMessage]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    var isThinking: Bool
    var text: String
}
