import SwiftUI

struct LocationDropdownView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Toggle button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Dropdown content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.blue)
                        
                        Text("Location:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    
                    Text("ECoRE Building")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .frame(width: 200)
                .transition(.scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
            }
        }
    }
}

/*#Preview {
    LocationDropdownView()
}*/
