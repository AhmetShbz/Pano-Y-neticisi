import SwiftUI

struct ClipboardView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    var onItemSelected: (String) -> Void
    
    var body: some View {
        List(clipboardManager.clipboardItems) { item in
            Button(action: {
                onItemSelected(item.text)
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.text)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    Text(item.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
} 