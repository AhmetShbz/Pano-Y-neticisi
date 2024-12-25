import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var clipboardManager = ClipboardManager.shared
    private var clipboardView: UIHostingController<ClipboardView>?
    private var updateTimer: Timer?
    private var lastPasteboardChangeCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardView()
        setupClipboardObservers()
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
    }
    
    private func setupKeyboardView() {
        let hostingController = UIHostingController(
            rootView: ClipboardView(
                clipboardManager: ClipboardManager.shared,
                onItemSelected: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                },
                onDismiss: { [weak self] in
                    self?.advanceToNextInputMode()
                }
            )
        )
        self.clipboardView = hostingController
        
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
        
        view.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let inputView = view as? UIInputView {
            inputView.frame.size.height = 350
        }
        clipboardManager.loadItems()
        updateKeyboardView()
    }
    
    private func setupClipboardObservers() {
        // Pano değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkPasteboardChanges),
            name: UIPasteboard.changedNotification,
            object: nil
        )
        
        // ClipboardManager değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClipboardManagerChanges),
            name: ClipboardManager.clipboardChangedNotification,
            object: nil
        )
        
        // Klavye görünür olduğunda yenile
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClipboardManagerChanges),
            name: UIResponder.keyboardWillShowNotification,
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
                if UIPasteboard.general.hasStrings {
                    DispatchQueue.main.async { [weak self] in
                        self?.clipboardManager.addItem(text)
                        self?.updateKeyboardView()
                    }
                }
            }
        }
    }
    
    @objc private func handleClipboardManagerChanges(_ notification: Notification? = nil) {
        DispatchQueue.main.async { [weak self] in
            // Özel silme işlemi kontrolü
            if let userInfo = notification?.userInfo,
               let action = userInfo["action"] as? String,
               action == "delete",
               let itemIdString = userInfo["itemId"] as? String,
               let itemId = UUID(uuidString: itemIdString) {
                // Silinen öğeyi klavye eklentisinden de kaldır
                if let index = self?.clipboardManager.clipboardItems.firstIndex(where: { $0.id == itemId }) {
                    self?.clipboardManager.clipboardItems.remove(at: index)
                }
            }
            
            self?.clipboardManager.loadItems()
            self?.updateKeyboardView()
        }
    }
    
    private func updateKeyboardView() {
        if let clipboardView = clipboardView {
            clipboardView.rootView = ClipboardView(
                clipboardManager: clipboardManager,
                onItemSelected: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                },
                onDismiss: { [weak self] in
                    self?.advanceToNextInputMode()
                }
            )
        }
    }
    
    override func dismissKeyboard() {
        advanceToNextInputMode()
    }
    
    deinit {
        updateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
} 
