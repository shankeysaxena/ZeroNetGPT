//
//  DocumentProcessor.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 24/07/25.
//

import Foundation
import Ollama
import PDFKit
import UniformTypeIdentifiers

enum FileProcessingState {
    case idle
    case processing
    case ready(_ url: URL)
    case failed(_ error: Error)
}

final class DocumentProcessor: ObservableObject {
    @Published var fileProcessingState: FileProcessingState = .idle
    private let llmService: LLMService
    
    @MainActor
    init() {
        self.llmService = .init(with: .default)
    }
    
    func streamResponse(for query: String) async throws -> AsyncThrowingStream<ResponseMessageChunk, Swift.Error> {
        return try await llmService.streamResponse(for: query)
    }
    
    func pickFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .plainText, .text]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await processFile(for: url)
            }
        }
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        let supportedTypes = SupportedFileTypes.allCases
        
        for provider in providers {
            if let matchedType = supportedTypes.first(where: {
                provider.hasItemConformingToTypeIdentifier($0.identifier)
            }) {
                handleDroppedItem(provider: provider, type: matchedType)
                return true
            }
        }
        return false
    }
    
    private func handleDroppedItem(provider: NSItemProvider, type: SupportedFileTypes) {
        provider.loadItem(
            forTypeIdentifier: type.identifier,
            options: nil
        ) { [weak self] item, error in
            guard let self = self else { return }
            
            if let fileURL = self.extractFileURL(from: item),
               self.isFileTypeSupported(fileURL) {
                Task {
                    await self.processFile(for: fileURL)
                }
            }
        }
    }
    
    private func extractFileURL(from item: Any?) -> URL? {
        if let nsURL = item as? NSURL {
            let url = nsURL as URL
            return url
        } else if let data = item as? Data {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            try? data.write(to: tempURL)
            return tempURL
        }
        return nil
    }
    
    private func isFileTypeSupported(_ url: URL) -> Bool {
        guard let fileType = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }
        return [UTType.pdf, .plainText, .text].contains { fileType.conforms(to: $0) }
    }
    
    private func processFile(for url: URL) async {
        await updateFileProcessingState(.processing)
        do {
            await llmService.resetEmbeddings()
            let text = try extractText(from: url)
            try await llmService.processFileText(text)
            await updateFileProcessingState(.ready(url))
        } catch {
            await updateFileProcessingState(.failed(error))
        }
    }
    
    @MainActor
    private func updateFileProcessingState(_ state: FileProcessingState) async {
        self.fileProcessingState = state
    }
    
    private func extractText(from url: URL) throws -> String {
        let extractor = TextExtractorFactory.createExtractor(for: url)
        return try extractor.extractText(from: url)
    }
}

private enum SupportedFileTypes: CaseIterable {
    case pdf
    case plainText
    case text
    case fileURL
    
    var identifier: String {
        switch self {
        case .pdf:
            return UTType.pdf.identifier
        case .plainText:
            return UTType.plainText.identifier
        case .text:
            return UTType.text.identifier
        case .fileURL:
            return UTType.fileURL.identifier
        }
    }
}
