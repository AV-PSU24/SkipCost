import SwiftUI

@main
struct TuitionClassMotivatorApp: App {
    @StateObject private var notifier = NotificationTimer()
    @State private var hasCompletedOnboarding = false
    @StateObject private var classStack = ClassStackShare.shared
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                let _ = print("This is classStack tuple: \(classStack.classSchedule)")
                MainToggleView()
                    .environmentObject(notifier)
                    .onAppear {
                        notifier.startTimer(with: classStack.classSchedule)
                        //print("This is classStack tuple: \(classStack.classSchedule)")
                    }
            }
            else {
                IntroFrames(isCompleted: $hasCompletedOnboarding)
            }
        }
    }
}

struct MainToggleView: View {
    @State private var selectedTab: Int = 0   // 0 = Invested, 1 = Wasted
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                
                // MARK: - Top Sliding Toggle
                ZStack {
                    // Outline capsule
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1.2)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                        .frame(width: 250, height: 36) // smaller and centered
                    
                    // Sliding highlight
                    HStack {
                        if selectedTab == 1 { Spacer() }
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                selectedTab == 0
                                ? LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.yellow, .orange, .red], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: 120, height: 30) // smaller highlight inside
                            .animation(.easeInOut(duration: 0.25), value: selectedTab)
                        if selectedTab == 0 { Spacer() }
                    }
                    .padding(.horizontal, 5)
                    .frame(width: 250) // match outer capsule width
                    
                    // Labels
                    HStack {
                        Button(action: { withAnimation { selectedTab = 0 } }) {
                            Text("💰 Invested")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTab == 0 ? .white : .gray)
                                .frame(maxWidth: .infinity)
                        }
                        Button(action: { withAnimation { selectedTab = 1 } }) {
                            Text("📉 Lost")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTab == 1 ? .white : .gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(width: 250, height: 36)
                }
                .padding(.top, 10)
                
                // MARK: - Active Screen
                if selectedTab == 0 {
                    MoneyInvested()
                } else {
                    MoneyWasted()
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            
            // MARK: - Location Button (appears on both frames)
            LocationDropdownView()
                .padding(.top, 5)
                .padding(.trailing, 16)
        }
    }
}
