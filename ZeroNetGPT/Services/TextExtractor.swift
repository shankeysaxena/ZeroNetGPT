//
//  TextExtractor.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 25/07/25.
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

protocol TextExtractor {
    func extractText(from url: URL) throws -> String
}

struct PDFTextExtractor: TextExtractor {
    func extractText(from url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw FileProcessingError.unableToOpenPDF
        }
        
        return (0..<pdfDocument.pageCount)
            .compactMap { pdfDocument.page(at: $0)?.string }
            .joined(separator: "\n")
    }
}

struct PlainTextExtractor: TextExtractor {
    func extractText(from url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }
}

struct TextExtractorFactory {
    static func createExtractor(for url: URL) -> TextExtractor {
        guard let fileType = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return PlainTextExtractor()
        }
        
        if fileType.conforms(to: .pdf) {
            return PDFTextExtractor()
        } else {
            return PlainTextExtractor()
        }
    }
}

enum FileProcessingError: LocalizedError {
    case unableToOpenPDF
}
