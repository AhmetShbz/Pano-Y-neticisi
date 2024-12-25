import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    private var clipboardManager = ClipboardManager.shared
    private var heightConstraint: NSLayoutConstraint?
    private var clipboardView: UIHostingController<ClipboardView>?
    private var isClipboardViewVisible = false
    private var updateTimer: Timer?
    private var lastPasteboardChangeCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardView()
        setupGestureRecognizer()
        setupClipboardObservers()
        
        // İlk açılışta pano durumunu kaydet
        lastPasteboardChangeCount = UIPasteboard.general.changeCount
    }
    
    private func setupClipboardObservers() {
        // Pano değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkPasteboardChanges),
            name: UIPasteboard.changedNotification,
            object: nil
        )
        
        // Timer'ı başlat (her 0.5 saniyede bir kontrol et)
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
    
    @objc private func refreshClipboardItems() {
        clipboardManager.loadItems()
        // SwiftUI view'ı güncelle
        if let clipboardView = clipboardView {
            clipboardView.rootView = ClipboardView(clipboardManager: clipboardManager) { [weak self] text in
                self?.insertText(text)
                self?.hideClipboardView()
            }
        }
    }
    
    deinit {
        updateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupKeyboardView() {
        // Klavye arka plan görünümü
        view.backgroundColor = .systemBackground
        
        // Kaydırma görünümü için container
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Container view constraints
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        heightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
        
        // SwiftUI view'ı oluştur
        let clipboardView = UIHostingController(rootView: ClipboardView(clipboardManager: clipboardManager) { text in
            self.insertText(text)
            self.hideClipboardView()
        })
        self.clipboardView = clipboardView
        
        // SwiftUI view'ı container'a ekle
        addChild(clipboardView)
        containerView.addSubview(clipboardView.view)
        clipboardView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            clipboardView.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            clipboardView.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            clipboardView.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            clipboardView.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        clipboardView.didMove(toParent: self)
    }
    
    private func setupGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            let newHeight = max(0, min(200, -translation.y))
            heightConstraint?.constant = newHeight
            
        case .ended:
            let shouldShow = velocity.y < 0 || heightConstraint?.constant ?? 0 > 100
            if shouldShow {
                showClipboardView()
            } else {
                hideClipboardView()
            }
            
        default:
            break
        }
    }
    
    private func showClipboardView() {
        isClipboardViewVisible = true
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint?.constant = 200
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideClipboardView() {
        isClipboardViewVisible = false
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint?.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }
} 