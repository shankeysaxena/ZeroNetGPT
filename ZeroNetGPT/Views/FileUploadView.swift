//
//  FileUploadView.swift
//  ZeroNetGPT
//
//  Created by Shivam Saxena on 25/07/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileUploadView: View {
    @State private var isTargeted = false
    let fileState: FileProcessingState
    let onDrop: ([NSItemProvider]) -> Bool
    let onPick: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            switch fileState {
            case .idle:
                Image(systemName: "tray.and.arrow.up.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                Text("Upload a file")
                    .font(.headline)
                Text("Drag and drop a file here, or click to browse")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Button("Choose File") {
                    onPick()
                }

            case .processing:
                ProgressView("Processing file...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()

            case .ready(let fileURL):
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(fileURL.lastPathComponent)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button("Upload New File") {
                        onPick()
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                }

            case .failed(let error):
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
                Text("Failed to process file")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Button("Choose Another File") {
                    onPick()
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .onDrop(
            of: [UTType.pdf, UTType.plainText, UTType.text],
            isTargeted: $isTargeted,
            perform: onDrop
        )
        .overlay(
            Group {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 3)
                        .padding(8)
                }
            }
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.blue.opacity(0.5))
        )
        .padding()
    }
}
