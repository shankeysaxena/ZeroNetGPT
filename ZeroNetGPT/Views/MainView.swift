//
//  MainView.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 24/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            FileUploadView(
                fileState: viewModel.fileProcessingState,
                onDrop: viewModel.handleFileDrop,
                onPick: viewModel.pickFile
            )
            Divider()
            ChatListView(messages: viewModel.messages)
            ChatInputView(viewModel: viewModel)
        }
    }
}
