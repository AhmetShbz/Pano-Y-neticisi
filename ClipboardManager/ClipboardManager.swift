import Foundation
import SwiftUI
import UIKit

public struct ClipboardItem: Identifiable, Codable {
    public let id: UUID
    public var text: String
    public let date: Date
    public var isPinned: Bool
    
    public init(text: String) {
        self.id = UUID()
        self.text = text
        self.date = Date()
        self.isPinned = false
    }
}

public class ClipboardManager: ObservableObject {
    public static let shared = ClipboardManager()
    
    @Published public var clipboardItems: [ClipboardItem] = []
    private let maxItems = 50
    public let userDefaults = UserDefaults(suiteName: "group.com.ahmtcanx.clipboardmanager")
    
    private var lastCopiedText: String?
    
    private init() {
        loadItems()
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Pano değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkClipboard),
            name: UIPasteboard.changedNotification,
            object: nil
        )
        
        // Uygulama arka plandan öne geldiğinde kontrol et
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkClipboard),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // İlk açılışta mevcut panoyu kontrol et
        checkClipboard()
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
    
    public func saveItems() {
        if let data = try? JSONEncoder().encode(clipboardItems) {
            userDefaults?.set(data, forKey: "clipboardItems")
        }
    }
    
    public func updateItem(_ item: ClipboardItem, newText: String) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].text = newText
            saveItems()
        }
    }
    
    public func shareItem(_ item: ClipboardItem) {
        // Paylaşım işlemi view tarafında yapılacak
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 