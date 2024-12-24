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
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateBackground = false
    
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
        ZStack {
            // Animasyonlu arka plan
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: animateBackground ? geometry.size.width * 0.3 : -geometry.size.width * 0.3,
                                y: animateBackground ? geometry.size.height * 0.2 : -geometry.size.height * 0.2)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: animateBackground ? -geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                y: animateBackground ? -geometry.size.height * 0.3 : geometry.size.height * 0.3)
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
                // İlerleme göstergesi
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Sayfa içeriği
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        PageView(page: pages[index], colorScheme: colorScheme) {
                            if currentPage < pages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
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

struct PageView: View {
    let page: OnboardingPage
    let colorScheme: ColorScheme
    let onContinue: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // İkon
            Image(systemName: page.image)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear { isAnimating = true }
            
            VStack(spacing: 16) {
                // Başlık
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                // Ana açıklama
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                // İkincil açıklama
                if let secondaryText = page.secondaryDescription {
                    Text(secondaryText)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            }
            .transition(.opacity)
            
            Spacer()
            
            // Aksiyon butonu
            if let buttonTitle = page.buttonTitle {
                Button(action: {
                    if let action = page.buttonAction {
                        action()
                    } else {
                        onContinue()
                    }
                }) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 30)
                .scaleEffect(isAnimating ? 1.0 : 0.95)
            }
            
            // İleri butonu
            if page.buttonTitle == nil {
                Button(action: onContinue) {
                    HStack {
                        Text("Devam Et")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.blue)
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
                .padding(.top, 10)
            }
            
            Spacer()
                .frame(height: 20)
        }
        .padding()
    }
} 