import SwiftUI

struct ClipboardView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    var onItemSelected: (String) -> Void
    var onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateBackground = false
    @State private var deleteTimer: Timer?
    
    var sortedItems: [ClipboardItem] {
        let pinnedItems = clipboardManager.clipboardItems.filter { $0.isPinned }
        let unpinnedItems = clipboardManager.clipboardItems.filter { !$0.isPinned }
        return pinnedItems + unpinnedItems
    }
    
    var body: some View {
        ZStack {
            // Animasyonlu arka plan
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.08))
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: animateBackground ? geometry.size.width * 0.3 : -geometry.size.width * 0.3,
                                y: animateBackground ? geometry.size.height * 0.2 : -geometry.size.height * 0.2)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.08))
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: animateBackground ? -geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                y: animateBackground ? -geometry.size.height * 0.2 : geometry.size.height * 0.2)
                        .blur(radius: 60)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                        animateBackground.toggle()
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        onDismiss()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 17))
                            Text("Klavye")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .padding(.leading, 12)
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    Button(action: {
                        onItemSelected("\n")
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "return")
                                .font(.system(size: 17))
                            Text("Sal")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .padding(.trailing, 6)
                    
                    Button(action: {
                        // Normal dokunmada tek karakter sil
                        if deleteTimer == nil {
                            onItemSelected("__DELETE__")
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 17))
                            Text("Sil")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { _ in
                                deleteTimer?.invalidate()
                                deleteTimer = nil
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .onEnded { _ in
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                // Sürekli silme için timer başlat
                                deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                    onItemSelected("__DELETE__")
                                    
                                    // Hafif titreşim geri bildirimi
                                    let lightGenerator = UIImpactFeedbackGenerator(style: .light)
                                    lightGenerator.impactOccurred()
                                }
                            }
                    )
                    .padding(.trailing, 12)
                }
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                
                if clipboardManager.clipboardItems.isEmpty {
                    // Boş durum görünümü
                    VStack(spacing: 16) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.blue.opacity(0.6))
                            .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Text("Henüz Kopyalanan Metin Yok")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Kopyaladığınız metinler burada görünecek")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sortedItems) { item in
                            ClipboardItemView(item: item) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onItemSelected(item.text)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        deleteItem(item)
                                    }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    withAnimation {
                                        togglePin(item)
                                    }
                                } label: {
                                    Label(item.isPinned ? "Sabitlemeyi Kaldır" : "Sabitle", 
                                          systemImage: item.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.blue)
                            }
                        }
                        
                        // Alt boşluk için görünmez öğe
                        Color.clear
                            .frame(height: 80)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .refreshable {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        clipboardManager.loadItems()
                    }
                }
            }
        }
        .onAppear {
            // ClipboardManager değişikliklerini dinle
            NotificationCenter.default.addObserver(
                forName: ClipboardManager.clipboardChangedNotification,
                object: nil,
                queue: .main
            ) { _ in
                clipboardManager.loadItems()
            }
        }
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        clipboardManager.deleteItem(item)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func togglePin(_ item: ClipboardItem) {
        clipboardManager.togglePinItem(item)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// Clipboard öğesi görünümü
struct ClipboardItemView: View {
    let item: ClipboardItem
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: getSystemImage(for: item.text))
                        .font(.system(size: 16))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text(getItemType(for: item.text))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeAgoDisplay(date: item.date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text(item.text)
                    .lineLimit(2)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.15) : Color.white.opacity(0.5))
                    .background(.ultraThinMaterial)
            )
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Metin türüne göre ikon seç
    private func getSystemImage(for text: String) -> String {
        if text.contains("@") { return "envelope.fill" }
        if text.contains("http") || text.contains("www") { return "link" }
        if text.filter({ $0.isNumber }).count > 8 { return "phone.fill" }
        return "doc.text.fill"
    }
    
    // Metin türünü belirle
    private func getItemType(for text: String) -> String {
        if text.contains("@") { return "E-posta" }
        if text.contains("http") || text.contains("www") { return "Link" }
        if text.filter({ $0.isNumber }).count > 8 { return "Telefon" }
        return "\(text.count) karakter"
    }
}

// Zaman gösterimi fonksiyonu
func timeAgoDisplay(date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
    
    if let day = components.day, day > 0 {
        return "\(day)g önce"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)s önce"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)d önce"
    } else {
        return "Şimdi"
    }
} 