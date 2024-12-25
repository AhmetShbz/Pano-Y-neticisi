import SwiftUI

struct ClipboardView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    var onItemSelected: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateBackground = false
    
    var body: some View {
        ZStack {
            // Animasyonlu arka plan
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: animateBackground ? geometry.size.width * 0.3 : -geometry.size.width * 0.3,
                                y: animateBackground ? geometry.size.height * 0.2 : -geometry.size.height * 0.2)
                        .blur(radius: 40)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: animateBackground ? -geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                y: animateBackground ? -geometry.size.height * 0.3 : geometry.size.height * 0.3)
                        .blur(radius: 40)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                        animateBackground.toggle()
                    }
                }
            }
            .ignoresSafeArea()
            
            if clipboardManager.clipboardItems.isEmpty {
                // Boş durum görünümü
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 50))
                        .foregroundColor(.blue.opacity(0.8))
                        .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
                    
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
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(clipboardManager.clipboardItems) { item in
                            ClipboardItemView(item: item) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onItemSelected(item.text)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// Clipboard öğesi görünümü
struct ClipboardItemView: View {
    let item: ClipboardItem
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: getSystemImage(for: item.text))
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    Text(getItemType(for: item.text))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeAgoDisplay(date: item.date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(item.text)
                    .lineLimit(2)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
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