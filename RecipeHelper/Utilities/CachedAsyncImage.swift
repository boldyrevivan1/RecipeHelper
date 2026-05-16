//
//  CachedAsyncImage.swift
//  RecipeHelper
//
//  Если url выглядит как "recipe_1" — берёт из Assets.
//  Если это http URL — скачивает из сети с кешем.
//

import SwiftUI

private actor ImageStore {
    static let shared  = ImageStore()
    static let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest  = 30
        c.timeoutIntervalForResource = 60
        c.waitsForConnectivity       = true
        return URLSession(configuration: c)
    }()
    private var cache: [String: UIImage] = [:]
    func get(_ key: String) -> UIImage? { cache[key] }
    func set(_ img: UIImage, for key: String) { cache[key] = img }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let urlString:   String?
    private let content:     (Image) -> Content
    private let placeholder: () -> Placeholder
    @State private var uiImage: UIImage?

    init(url: String?,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.urlString   = url
        self.content     = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let img = uiImage {
                content(Image(uiImage: img))
            } else {
                placeholder()
                    .task(id: urlString) { await load() }
            }
        }
    }

    private func load() async {
        guard let str = urlString, !str.isEmpty else { return }

        // 1. Check cache
        if let cached = await ImageStore.shared.get(str) {
            uiImage = cached; return
        }

        // 2. Try Assets.xcassets first (works offline, no URL needed)
        if let img = UIImage(named: str) {
            await ImageStore.shared.set(img, for: str)
            uiImage = img
            return
        }

        // 3. Download from network
        guard let url = URL(string: str) else { return }
        for attempt in 1...3 {
            do {
                let (data, _) = try await ImageStore.session.data(from: url)
                if let img = UIImage(data: data) {
                    await ImageStore.shared.set(img, for: str)
                    uiImage = img
                    return
                }
            } catch {
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }
    }
}
