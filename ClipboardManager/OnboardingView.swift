import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "keyboard",
            title: "Klavye Eklentisi",
            description: "Klavye eklentisini etkinleştirerek kopyaladığınız metinlere her yerden erişebilirsiniz."
        ),
        OnboardingPage(
            image: "doc.on.clipboard",
            title: "Pano Erişimi",
            description: "Uygulamanın pano içeriğinize erişmesine izin vererek kopyaladığınız metinleri otomatik olarak kaydedebilirsiniz."
        ),
        OnboardingPage(
            image: "checkmark.circle",
            title: "Hazırsınız!",
            description: "Artık uygulamayı kullanmaya başlayabilirsiniz."
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(systemName: pages[index].image)
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(pages[index].title)
                            .font(.title)
                            .bold()
                        
                        Text(pages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .foregroundColor(.secondary)
                    }
                    .tag(index)
                    .padding()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    setupApp()
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Devam Et" : "Başla")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
    
    private func setupApp() {
        // Klavye eklentisi ayarlarını aç
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        
        // Onboarding'i tamamla
        onboardingManager.completeOnboarding()
    }
} 