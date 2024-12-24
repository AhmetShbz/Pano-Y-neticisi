import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showSettings = false
    @State private var animateBackground = false
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            let pinnedItems = clipboardManager.clipboardItems.filter { $0.isPinned }
            let unpinnedItems = clipboardManager.clipboardItems.filter { !$0.isPinned }
            return pinnedItems + unpinnedItems
        } else {
            return clipboardManager.clipboardItems.filter { item in
                item.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        Group {
            if !onboardingManager.isOnboardingCompleted {
                OnboardingView(onboardingManager: onboardingManager)
            } else {
                NavigationView {
                    ZStack {
                        // Animasyonlu arka plan
                        GeometryReader { geometry in
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: geometry.size.width * 0.6)
                                    .offset(x: animateBackground ? geometry.size.width * 0.3 : -geometry.size.width * 0.3,
                                            y: animateBackground ? geometry.size.height * 0.2 : -geometry.size.height * 0.2)
                                    .blur(radius: 50)
                                
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: geometry.size.width * 0.8)
                                    .offset(x: animateBackground ? -geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                            y: animateBackground ? -geometry.size.height * 0.3 : geometry.size.height * 0.3)
                                    .blur(radius: 50)
                            }
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                                    animateBackground.toggle()
                                }
                            }
                        }
                        .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            if !clipboardManager.clipboardItems.isEmpty {
                                // Arama alanı
                                SearchBar(text: $searchText)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                            }
                            
                            if clipboardManager.clipboardItems.isEmpty {
                                // Boş durum görünümü
                                VStack(spacing: 24) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 70))
                                        .foregroundColor(.blue.opacity(0.8))
                                        .padding(.bottom, 10)
                                        .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 5)
                                    
                                    Text("Henüz Kopyalanan Metin Yok")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Herhangi bir metni kopyaladığınızda\notomatik olarak burada listelenecek")
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                    
                                    Spacer()
                                }
                                .padding(.top, 60)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                if filteredItems.isEmpty {
                                    // Arama sonucu boş durumu
                                    VStack(spacing: 16) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        
                                        Text("Sonuç Bulunamadı")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text("\"\(searchText)\" ile eşleşen bir sonuç yok")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.top, 60)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    // Kopyalanan metinler listesi
                                    List {
                                        ForEach(filteredItems) { item in
                                            ClipboardItemView(item: item) {
                                                UIPasteboard.general.string = item.text
                                                showToastMessage("Kopyalandı: \(item.text)")
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        deleteItem(item)
                                                    }
                                                } label: {
                                                    Label("Sil", systemImage: "trash")
                                                }
                                                .tint(.red)
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                Button {
                                                    withAnimation {
                                                        togglePin(item)
                                                    }
                                                } label: {
                                                    Label(item.isPinned ? "Sabitlemeyi Kaldır" : "Sabitle", 
                                                          systemImage: item.isPinned ? "pin.slash" : "pin")
                                                }
                                                .tint(item.isPinned ? .gray : .blue)
                                            }
                                        }
                                    }
                                    .listStyle(PlainListStyle())
                                    .refreshable {
                                        // Yenileme animasyonu için boş işlem
                                    }
                                }
                            }
                            
                            // Toast mesajı
                            if showToast {
                                ToastView(message: toastMessage)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .zIndex(1)
                            }
                        }
                    }
                    .navigationTitle("Pano Geçmişi")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            if !clipboardManager.clipboardItems.isEmpty {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        clipboardManager.clipboardItems.removeAll()
                                        clipboardManager.userDefaults?.removeObject(forKey: "clipboardItems")
                                        searchText = "" // Temizleme işleminde arama metnini de sıfırla
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .buttonStyle(ToolbarButtonStyle())
                            }
                            
                            Menu {
                                Button(action: {
                                    UserDefaults.standard.removeObject(forKey: "isOnboardingCompleted")
                                    onboardingManager.isOnboardingCompleted = false
                                }) {
                                    Label("Kurulum Sihirbazı", systemImage: "wand.and.stars")
                                }
                                
                                Button(action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Label("Klavye Ayarları", systemImage: "keyboard")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .buttonStyle(ToolbarButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        withAnimation {
            self.toastMessage = message
            self.showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showToast = false
            }
        }
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        if let index = clipboardManager.clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardManager.clipboardItems.remove(at: index)
            clipboardManager.saveItems()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showToastMessage("Öğe silindi")
        }
    }
    
    private func togglePin(_ item: ClipboardItem) {
        if let index = clipboardManager.clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardManager.clipboardItems[index].isPinned.toggle()
            clipboardManager.saveItems()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showToastMessage(clipboardManager.clipboardItems[index].isPinned ? "Sabitlendi" : "Sabitleme kaldırıldı")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Metinlerde Ara...", text: $text)
                .font(.system(size: 16))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(colorScheme == .dark ? .systemGray6 : .systemGray6))
        )
    }
}

struct ToastView: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(message)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .padding(.bottom, 20)
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.text)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(45))
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.date.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .opacity(isPressed ? 0.7 : 1.0)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(ClipboardItemButtonStyle())
    }
}

struct ClipboardItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .contentShape(Circle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Dün" : "\(day) gün önce"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) saat önce"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) dakika önce"
        } else {
            return "Az önce"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 