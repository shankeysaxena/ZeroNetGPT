//
//  EmbeddingsStore.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 24/07/25.
//

import Foundation
import Ollama

struct TextChunk {
    let text: String
    let embedding: [Double]
}

actor EmbeddingsStore {
    private static let embeddingModelID: Model.ID = "nomic-embed-text"
    private var chunks: [TextChunk] = []

    func fetchAndStoreEmbeddings(from chunks: [String], with client: Ollama.Client) async throws {
        let embeddings = try await getEmbeddings(for: chunks, with: client)
        let textChunks: [TextChunk] = zip(chunks, embeddings).map(
            { TextChunk(text: $0.0, embedding: $0.1) }
        )
        self.chunks.append(contentsOf: textChunks)
    }
    
    func getEmbeddings(for chunks: [String], with client: Ollama.Client) async throws -> [[Double]] {
        guard !chunks.isEmpty else {
            return []
        }
        let embeddings = try await client.embed(model: EmbeddingsStore.embeddingModelID, inputs: chunks)
        return embeddings.embeddings.rawValue
    }
    
    func resetEmbeddings() {
        chunks = []
    }

    func search(_ queryEmbedding: [Double], topK: Int = 3) -> [TextChunk] {
        return chunks
            .map { ($0, cosineSimilarity($0.embedding, queryEmbedding)) }
            .sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { $0.0 }
    }

    private func addChunk(_ chunk: TextChunk) {
        chunks.append(chunk)
    }
    
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        guard normA > 0 && normB > 0 else {
            return 0
        }
        return dotProduct / (normA * normB)
    }
}


