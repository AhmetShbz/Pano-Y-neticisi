import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showingAlert = false
    @State private var selectedText: String?
    
    var body: some View {
        Group {
            if !onboardingManager.isOnboardingCompleted {
                OnboardingView(onboardingManager: onboardingManager)
            } else {
                NavigationView {
                    List {
                        if clipboardManager.clipboardItems.isEmpty {
                            Section {
                                VStack(spacing: 16) {
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    
                                    Text("Henüz kopyalanmış metin yok")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text("Herhangi bir metni kopyaladığınızda burada görünecek")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        } else {
                            ForEach(clipboardManager.clipboardItems) { item in
                                Button(action: {
                                    UIPasteboard.general.string = item.text
                                    selectedText = item.text
                                    showingAlert = true
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(item.text)
                                            .font(.body)
                                            .lineLimit(3)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            Image(systemName: "clock")
                                                .foregroundColor(.gray)
                                            Text(item.date, style: .time)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete(perform: deleteItems)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("Pano Geçmişi")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            if !clipboardManager.clipboardItems.isEmpty {
                                EditButton()
                            }
                            
                            Button(action: {
                                UserDefaults.standard.removeObject(forKey: "isOnboardingCompleted")
                                onboardingManager.isOnboardingCompleted = false
                            }) {
                                Image(systemName: "arrow.clockwise.circle")
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
    
    private func deleteItems(at offsets: IndexSet) {
        clipboardManager.clipboardItems.remove(atOffsets: offsets)
        if let data = try? JSONEncoder().encode(clipboardManager.clipboardItems) {
            clipboardManager.userDefaults?.set(data, forKey: "clipboardItems")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 