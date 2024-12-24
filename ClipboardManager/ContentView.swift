import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showingAlert = false
    @State private var selectedText: String?
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            if !onboardingManager.isOnboardingCompleted {
                OnboardingView(onboardingManager: onboardingManager)
            } else {
                NavigationView {
                    ZStack {
                        // Arka plan gradyanı
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(colorScheme == .dark ? 0.1 : 0.05),
                                Color.purple.opacity(colorScheme == .dark ? 0.1 : 0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        
                        if clipboardManager.clipboardItems.isEmpty {
                            // Boş durum görünümü
                            VStack(spacing: 20) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 10)
                                
                                Text("Henüz Kopyalanan Metin Yok")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.primary)
                                
                                Text("Herhangi bir metni kopyaladığınızda\notomatik olarak burada listelenecek")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Kopyalanan metinler listesi
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(clipboardManager.clipboardItems) { item in
                                        ClipboardItemView(item: item) {
                                            UIPasteboard.general.string = item.text
                                            selectedText = item.text
                                            showingAlert = true
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .navigationTitle("Pano Geçmişi")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            if !clipboardManager.clipboardItems.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        clipboardManager.clipboardItems.removeAll()
                                        clipboardManager.userDefaults?.removeObject(forKey: "clipboardItems")
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
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
                            }
                        }
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("Kopyalandı"),
                            message: Text(selectedText ?? ""),
                            dismissButton: .default(Text("Tamam"))
                        )
                    }
                }
            }
        }
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
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
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(colorScheme == .dark ? .systemGray6 : .white))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
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