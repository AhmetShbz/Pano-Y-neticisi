import Foundation
import SwiftUI
import UIKit

// Bildirim adını tanımla
public extension Notification.Name {
    static let clipboardItemAdded = Notification.Name("clipboardItemAdded")
}

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
    private var lastPasteboardChangeCount: Int = UIPasteboard.general.changeCount
    private var updateTimer: Timer?
    
    static let clipboardChangedNotification = Notification.Name("ClipboardManagerDataChanged")
    
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
        
        // Darwin bildirimlerini dinle
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let name = "com.ahmtcanx.clipboardmanager.dataChanged" as CFString
        
        CFNotificationCenterAddObserver(center,
                                      observer,
                                      { (_, observer, name, _, _) in
            let manager = Unmanaged<ClipboardManager>.fromOpaque(observer!).takeUnretainedValue()
            DispatchQueue.main.async {
                manager.loadItems()
            }
        },
                                      name as CFString,
                                      nil,
                                      .deliverImmediately)
        
        // Periyodik kontrol başlat
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboardChanges()
        }
        
        // İlk açılışta mevcut panoyu kontrol et
        checkClipboard()
    }
    
    @objc private func checkPasteboardChanges() {
        let currentChangeCount = UIPasteboard.general.changeCount
        
        if currentChangeCount != lastPasteboardChangeCount {
            lastPasteboardChangeCount = currentChangeCount
            checkClipboard()
        }
    }
    
    @objc private func checkClipboard() {
        if let text = UIPasteboard.general.string,
           !text.isEmpty && text != lastCopiedText {
            // Sadece kullanıcının kopyaladığı metinleri kaydet
            if UIPasteboard.general.hasStrings {
                lastCopiedText = text
                DispatchQueue.main.async {
                    self.addItem(text)
                }
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
        
        // Bildirim yayınla
        NotificationCenter.default.post(name: .clipboardItemAdded, object: nil)
    }
    
    public func loadItems() {
        if let data = userDefaults?.data(forKey: "clipboardItems"),
           let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            clipboardItems = items
            lastCopiedText = items.first?.text
        }
    }
    
    public func saveItems() {
        if let data = try? JSONEncoder().encode(clipboardItems) {
            userDefaults?.set(data, forKey: "clipboardItems")
            userDefaults?.synchronize()
            
            // Veri değişikliğini hemen bildir
            DispatchQueue.main.async {
                self.notifyClipboardChanged()
                
                // Darwin bildirimini de gönder
                let center = CFNotificationCenterGetDarwinNotifyCenter()
                let name = "com.ahmtcanx.clipboardmanager.dataChanged" as CFString
                CFNotificationCenterPostNotification(center, CFNotificationName(name), nil, nil, true)
            }
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
    
    public func deleteItem(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems.remove(at: index)
            saveItems()
            
            // Ana uygulamaya ve klavye eklentisine özel bildirim gönder
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: ClipboardManager.clipboardChangedNotification, object: nil, userInfo: ["action": "delete", "itemId": item.id.uuidString])
            }
        }
    }
    
    public func togglePinItem(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isPinned.toggle()
            saveItems()
            notifyClipboardChanged()
        }
    }
    
    public func clearAllItems() {
        clipboardItems.removeAll()
        userDefaults?.removeObject(forKey: "clipboardItems")
        notifyClipboardChanged()
    }
    
    private func notifyClipboardChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: ClipboardManager.clipboardChangedNotification, object: nil)
            
            // Değişiklikleri hemen yükle
            self.loadItems()
            
            // Diğer hedeflere de bildir
            NotificationCenter.default.post(name: .clipboardItemAdded, object: nil)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        
        // Darwin observer'ı temizle
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveObserver(center, observer, nil, nil)
    }
} 