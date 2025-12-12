//
//  FileContentView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 11.12.25.
//

import SwiftUI

struct FileContentView: View {
    let fileURL: URL
    let filename: String
    
    @State private var fileContent: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading file...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        
                        Text("Failed to load file")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if fileContent != "" {
                    TextEditor(text: $fileContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                } else {
                    Text("No content available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(filename)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear() {
                loadFileContent()
            }
        }
    }
    
    private func loadFileContent() {
        isLoading = true
        errorMessage = nil
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            isLoading = false
            fileContent = content
        } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)"
                isLoading = false
        }
    }
}

#Preview {
    FileContentView(
        fileURL: URL(fileURLWithPath: "/tmp/test.txt"),
        filename: "test.txt"
    )
}

