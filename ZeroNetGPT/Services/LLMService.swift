//
//  LLMService.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 24/07/25.
//

import Foundation
import Ollama

final class LLMService {
    private static let llmModel: Model.ID = "gemma3"
    private let client: Ollama.Client
    private let store: EmbeddingsStore
    
    init(with client: Ollama.Client) {
        self.client = client
        self.store = .init()
    }
    
    func processFileText(_ text: String) async throws {
        let chunks: [String] = chunk(text: text)
        try await store.fetchAndStoreEmbeddings(from: chunks, with: client)
    }
    
    func resetEmbeddings() async {
        await store.resetEmbeddings()
    }
    
    func processQuery(_ query: String) async throws -> String {
        let relatedChunks = try await retrieveEmbeddedChunks(for: query)
        let prompt = createQueryPrompt(for: query, with: relatedChunks)
        return try await answerQuestion(with: prompt)
    }
    
    func streamResponse(
        for query: String
    ) async throws -> AsyncThrowingStream<ResponseMessageChunk, Swift.Error> {
        let relatedChunks = try await retrieveEmbeddedChunks(for: query)
        let prompt = createQueryPrompt(for: query, with: relatedChunks)
        let stream = await client.generateStream(model: LLMService.llmModel, prompt: prompt)
        
        let asyncStream =  AsyncThrowingStream<ResponseMessageChunk, Swift.Error>(
            bufferingPolicy: .unbounded
        ) { continuation in
            let task = Task {
                do {
                    for try await response in stream {
                        let chunk = LLMResponseMapper.map(response)
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
        
        return asyncStream
    }
    
    private func createQueryPrompt(for query: String, with contextChunks: [TextChunk]) -> String {
        let context = contextChunks.map { $0.text }.joined(separator: "\n")
        
        let prompt = """
            You are an assistant helping with questions about the content
            with following context: 
            
            \(context)
            
            Question: \(query)
            """
        
        return prompt
    }
    
    private func answerQuestion(with prompt: String, model: Model.ID = "gemma3") async throws -> String {
        let response = try await client.generate(model: model, prompt: prompt)
        return response.response
    }
    
    private func retrieveEmbeddedChunks(for query: String) async throws -> [TextChunk] {
        let embeddingResponse = try await store.getEmbeddings(for: [query], with: client)
        guard let queryEmbedding = embeddingResponse.first else {
            throw Error.queryEmbeddingsRetrievalError
        }

        return await store.search(queryEmbedding)
    }
    
    private func chunk(text: String, size: Int = 500, overlap: Int = 100) -> [String] {
        var chunks = [String]()
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var index = 0

        while index < words.count {
            let end = min(index + size, words.count)
            let chunk = words[index..<end].joined(separator: " ")
            chunks.append(chunk)
            index += size - overlap
        }
        return chunks
    }
}

extension LLMService {
    enum Error: Swift.Error {
        case queryEmbeddingsRetrievalError
    }
}

struct ResponseMessageChunk: Identifiable, Codable {
    let id = UUID()
    let text: String
    let isFinal: Bool
    let thinking: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case isFinal
        case thinking
    }

    init(text: String, isFinal: Bool = false, thinking: String? = nil) {
        self.text = text
        self.isFinal = isFinal
        self.thinking = thinking
    }
}

enum LLMResponseMapper {
    static func map(_ response: Client.GenerateResponse) -> ResponseMessageChunk {
        ResponseMessageChunk(
            text: response.response,
            isFinal: response.done,
            thinking: response.thinking
        )
    }
}
