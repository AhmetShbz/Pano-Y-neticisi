import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var clipboardManager = ClipboardManager.shared
    private var clipboardView: UIHostingController<ClipboardView>?
    private var updateTimer: Timer?
    private var lastPasteboardChangeCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(
            rootView: ClipboardView(
                clipboardManager: ClipboardManager.shared,
                onItemSelected: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                }
            )
        )
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Klavye yüksekliğini ayarla
        view.heightAnchor.constraint(equalToConstant: 400).isActive = true
        
        setupClipboardObservers()
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Her görünüm öncesi yüksekliği güncelle
        if let inputView = view as? UIInputView {
            inputView.frame.size.height = 400
        }
    }
    
    private func setupClipboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkPasteboardChanges),
            name: UIPasteboard.changedNotification,
            object: nil
        )
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboardChanges()
        }
    }
    
    @objc private func checkPasteboardChanges() {
        let currentChangeCount = UIPasteboard.general.changeCount
        
        if currentChangeCount != lastPasteboardChangeCount {
            lastPasteboardChangeCount = currentChangeCount
            
            if let text = UIPasteboard.general.string, !text.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    self?.clipboardManager.addItem(text)
                    self?.refreshClipboardItems()
                }
            }
        }
    }
    
    private func refreshClipboardItems() {
        clipboardManager.loadItems()
        if let clipboardView = clipboardView {
            clipboardView.rootView = ClipboardView(clipboardManager: clipboardManager) { [weak self] text in
                self?.insertText(text)
            }
        }
    }
    
    deinit {
        updateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }
} 