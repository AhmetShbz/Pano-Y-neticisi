import SwiftUI
import UIKit

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let secondaryDescription: String?
}

struct OnboardingView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @State private var currentPage = 0
    
    var pages: [OnboardingPage] {
        [
            OnboardingPage(
                image: "keyboard.fill",
                title: "Hoş Geldiniz!",
                description: "Pano Yöneticisi ile kopyaladığınız her şeye anında erişin.",
                buttonTitle: nil,
                buttonAction: nil,
                secondaryDescription: "Hızlı ve kolay kullanım için klavye eklentimizi kuralım."
            ),
            OnboardingPage(
                image: "keyboard.badge.eye.fill",
                title: "Klavye Eklentisi",
                description: "Klavye eklentimiz sayesinde kopyaladığınız metinlere her uygulamada kolayca erişebilirsiniz.",
                buttonTitle: "Klavye Ayarlarını Aç",
                buttonAction: openKeyboardSettings,
                secondaryDescription: "Ayarlar > Klavye > Klavyeler > Yeni Klavye Ekle"
            ),
            OnboardingPage(
                image: "arrow.right.doc.on.clipboard.fill",
                title: "Kurulum Adımları",
                description: "1️⃣ 'Klavyeler'e dokunun\n2️⃣ 'Yeni Klavye Ekle' seçeneğine gidin\n3️⃣ 'Pano Yöneticisi'ni bulun\n4️⃣ Klavyeyi etkinleştirin",
                buttonTitle: "Anladım, Devam Et",
                buttonAction: nil,
                secondaryDescription: "💡 İpucu: Tüm adımları tamamladıktan sonra 'Devam Et' butonuna basın"
            ),
            OnboardingPage(
                image: "lock.shield.fill",
                title: "Tam Erişim",
                description: "Kopyaladığınız metinlere erişebilmek için klavyeye 'Tam Erişim' izni gerekiyor.",
                buttonTitle: "Tam Erişimi Etkinleştir",
                buttonAction: openFullAccessSettings,
                secondaryDescription: "🔒 Güvenliğiniz bizim için önemli. Bu izin sadece pano içeriğine erişmek için kullanılacak."
            ),
            OnboardingPage(
                image: "checkmark.seal.fill",
                title: "Her Şey Hazır!",
                description: "Artık kopyaladığınız her şey otomatik olarak kaydedilecek.",
                buttonTitle: "Uygulamayı Kullanmaya Başla",
                buttonAction: { onboardingManager.completeOnboarding() },
                secondaryDescription: "📱 Herhangi bir uygulamada klavye simgesine basılı tutup Pano Yöneticisi'ni seçerek kayıtlı metinlerinize ulaşabilirsiniz."
            )
        ]
    }
    
    var body: some View {
        @Environment(\.colorScheme) var colorScheme
        
        ZStack {
            // Arka plan gradyanı
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1),
                    Color.purple.opacity(colorScheme == .dark ? 0.2 : 0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // İlerleme göstergesi
                HStack {
                    ForEach(0..<pages.count) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 20 : 7, height: 7)
                            .contentTransition(.interpolate)
                    }
                }
                .padding(.top)
                
                // Sayfa içeriği
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 25) {
                            Spacer()
                            
                            // İkon
                            Image(systemName: pages[index].image)
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .symbolRenderingMode(.hierarchical)
                                .symbolEffect(.bounce, value: currentPage)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 16) {
                                // Başlık
                                Text(pages[index].title)
                                    .font(.title)
                                    .bold()
                                    .multilineTextAlignment(.center)
                                
                                // Ana açıklama
                                Text(pages[index].description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .foregroundColor(.secondary)
                                
                                // İkincil açıklama
                                if let secondaryText = pages[index].secondaryDescription {
                                    Text(secondaryText)
                                        .font(.callout)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .foregroundColor(.blue)
                                        .padding(.top, 8)
                                }
                            }
                            
                            Spacer()
                            
                            // Aksiyon butonu
                            if let buttonTitle = pages[index].buttonTitle {
                                Button(action: {
                                    if let action = pages[index].buttonAction {
                                        action()
                                    }
                                }) {
                                    Text(buttonTitle)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                        }
                                }
                                .padding(.horizontal, 30)
                                .buttonStyle(.bounce)
                            }
                            
                            // İleri butonu (son sayfada gizli)
                            if currentPage < pages.count - 1 {
                                Button(action: {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }) {
                                    HStack {
                                        Text("Devam Et")
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.blue)
                                    .font(.headline)
                                }
                                .padding(.top, 10)
                                .buttonStyle(.bounce)
                            }
                            
                            Spacer()
                                .frame(height: 20)
                        }
                        .tag(index)
                        .padding()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openFullAccessSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
} 