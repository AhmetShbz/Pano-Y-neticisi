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
    @State private var showNextButton = false
    @State private var dragOffset = CGSize.zero
    
    var pages: [OnboardingPage] {
        [
            OnboardingPage(
                image: "keyboard.fill",
                title: "Hoş Geldiniz! 👋",
                description: "Pano Yöneticisi ile kopyaladığınız her şeye anında erişin ve üretkenliğinizi artırın. Hızlı, güvenli ve kullanımı kolay!",
                buttonTitle: nil,
                buttonAction: nil,
                secondaryDescription: "Hızlı ve kolay kullanım için klavye eklentimizi birlikte kuralım. Sadece birkaç adım kaldı! 🚀"
            ),
            OnboardingPage(
                image: "doc.on.clipboard",
                title: "Kurulum Adımları 📝",
                description: "1️⃣ Ayarlar > Klavye > Klavyeler\n2️⃣ 'Yeni Klavye Ekle' > Pano Yöneticisi\n3️⃣ Tam Erişim'i Etkinleştir",
                buttonTitle: "Klavye Ayarlarını Aç",
                buttonAction: openKeyboardSettings,
                secondaryDescription: "🔒 Tam Erişim izni sadece kopyaladığınız metinlere erişmek için kullanılır ve verileriniz güvende kalır."
            ),
            OnboardingPage(
                image: "checkmark.seal.fill",
                title: "Her Şey Hazır! 🎉",
                description: "Tebrikler! Artık kopyaladığınız her şey otomatik olarak kaydedilecek ve her yerde erişilebilir olacak. Üretkenliğinizi artırmaya hazırsınız!",
                buttonTitle: "Uygulamayı Kullanmaya Başla",
                buttonAction: { onboardingManager.completeOnboarding() },
                secondaryDescription: "📱 Herhangi bir uygulamada klavye simgesine basılı tutup Pano Yöneticisi'ni seçerek kayıtlı metinlerinize ulaşabilirsiniz.\n✨ İyi kullanımlar!"
            )
        ]
    }
    
    var body: some View {
        ZStack {
            // Animasyonlu arka plan
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: animateBackground ? geometry.size.width * 0.3 : -geometry.size.width * 0.3,
                                y: animateBackground ? geometry.size.height * 0.2 : -geometry.size.height * 0.2)
                        .blur(radius: 80)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: geometry.size.width)
                        .offset(x: animateBackground ? -geometry.size.width * 0.2 : geometry.size.width * 0.2,
                                y: animateBackground ? -geometry.size.height * 0.3 : geometry.size.height * 0.3)
                        .blur(radius: 80)
                    
                    Circle()
                        .fill(Color.pink.opacity(0.1))
                        .frame(width: geometry.size.width * 0.7)
                        .offset(x: animateBackground ? geometry.size.width * 0.1 : -geometry.size.width * 0.1,
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
                // İlerleme göstergesi
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                            .shadow(color: currentPage == index ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
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
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    self.dragOffset = gesture.translation
                                }
                                .onEnded { gesture in
                                    let threshold: CGFloat = 50
                                    if gesture.translation.width > threshold && currentPage > 0 {
                                        withAnimation {
                                            currentPage -= 1
                                        }
                                    } else if gesture.translation.width < -threshold && currentPage < pages.count - 1 {
                                        withAnimation {
                                            currentPage += 1
                                        }
                                    }
                                    self.dragOffset = .zero
                                }
                        )
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.3).delay(0.3)) {
                                showNextButton = true
                            }
                        }
                        .onDisappear {
                            showNextButton = false
                        }
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
    @State private var showContent = false
    @State private var rotation3D = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // İkon
            Image(systemName: page.image)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .rotationEffect(.degrees(isAnimating ? 8 : -8))
                .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear { 
                    isAnimating = true
                    withAnimation(.easeIn(duration: 0.5)) {
                        showContent = true
                    }
                }
                .onDisappear {
                    showContent = false
                }
            
            VStack(spacing: 16) {
                // Başlık
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.blue)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // Ana açıklama
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                // İkincil açıklama
                if let secondaryText = page.secondaryDescription {
                    Text(secondaryText)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
            }
            .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
            
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
                            Color.blue
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 12, x: 0, y: 6)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
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
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                .padding(.top, 10)
            }
            
            Spacer()
                .frame(height: 20)
        }
        .padding()
    }
} 