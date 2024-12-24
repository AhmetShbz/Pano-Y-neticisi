import Foundation
import SwiftUI
import UIKit

public struct ClipboardItem: Identifiable, Codable {
    public let id: UUID
    public let text: String
    public let date: Date
    
    public init(text: String) {
        self.id = UUID()
        self.text = text
        self.date = Date()
    }
}

public class ClipboardManager: ObservableObject {
    public static let shared = ClipboardManager()
    
    @Published public var clipboardItems: [ClipboardItem] = []
    private let maxItems = 50
    public let userDefaults = UserDefaults(suiteName: "group.com.ahmtcanx.clipboardmanager")
    
    private var lastCopiedText: String?
    private var timer: Timer?
    
    private init() {
        loadItems()
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Her 1 saniyede bir panodaki değişiklikleri kontrol et
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        timer?.fire() // İlk kontrolü hemen yap
        
        // Uygulama arka plana geçtiğinde ve öne geldiğinde de kontrol et
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkClipboard),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func checkClipboard() {
        if let text = UIPasteboard.general.string,
           !text.isEmpty && text != lastCopiedText {
            lastCopiedText = text
            DispatchQueue.main.async {
                self.addItem(text)
            }
        }
    }
    
    public func addItem(_ text: String) {
        let item = ClipboardItem(text: text)
        
        // Aynı metin zaten varsa, eski olanı sil
        if let existingIndex = clipboardItems.firstIndex(where: { $0.text == text }) {
            clipboardItems.remove(at: existingIndex)
        }
        
        clipboardItems.insert(item, at: 0)
        
        if clipboardItems.count > maxItems {
            clipboardItems.removeLast()
        }
        
        saveItems()
    }
    
    private func loadItems() {
        if let data = userDefaults?.data(forKey: "clipboardItems"),
           let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            clipboardItems = items
            lastCopiedText = items.first?.text
        }
    }
    
    private func saveItems() {
        if let data = try? JSONEncoder().encode(clipboardItems) {
            userDefaults?.set(data, forKey: "clipboardItems")
        }
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
} 