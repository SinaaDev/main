//
//  TestUploading.swift
//  TestEveryThing
//
//  Created by TOTI SABZ on 4/22/25.
//


import SwiftUI
import UniformTypeIdentifiers   // ← for UTType

extension URL {
    /// Ask the system for the “preferred” MIME type for this file URL
    var mimeType: String {
        // 1. Grab the path‐extension
        let ext = self.pathExtension.lowercased()
        // 2. Ask UTType to map it to a UTI
        if let ut = UTType(filenameExtension: ext),
           // 3. And then get its preferred MIME
           let mime = ut.preferredMIMEType {
            return mime
        }
        // 4. Fallback
        return "application/octet-stream"
    }
}

class BinaryUploadViewModel: ObservableObject {
    @Published var status: String?

    /// Your upload endpoint
    private let uploadURL = URL(string: "http://3.7.15.131:8082/api/v1/files/upload?folderId=556")!

    func uploadBinary(fileURL: URL) {
        var req = URLRequest(url: uploadURL)
        req.httpMethod = "POST"
        // **Now dynamic**: insert the mimeType from our URL extension
        req.setValue(fileURL.mimeType, forHTTPHeaderField: "Content-Type")

        status = "Uploading…"
        let task = URLSession.shared.uploadTask(with: req, fromFile: fileURL) { data, resp, err in
            DispatchQueue.main.async {
                if let err = err {
                    self.status = "❌ Error: \(err.localizedDescription)"
                } else if let code = (resp as? HTTPURLResponse)?.statusCode,
                          (200..<300).contains(code) {
                    self.status = "✅ Upload succeeded!"
                } else {
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                    self.status = "❌ Server error (status \(code))"
                }
            }
        }
        task.resume()
    }
}


struct BinaryUploadView: View {
    @StateObject private var vm = BinaryUploadViewModel()
    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: 20) {
            if let s = vm.status {
                Text(s)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button("Select File…") {
                showingPicker = true
            }
            .fileImporter(
                isPresented: $showingPicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    vm.uploadBinary(fileURL: url)
                case .failure(let err):
                    vm.status = "❌ Picker error: \(err.localizedDescription)"
                }
            }
        }
        .padding()
    }
}


#Preview {
    BinaryUploadView()
}
