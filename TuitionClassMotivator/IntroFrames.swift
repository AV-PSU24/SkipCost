import SwiftUI

struct IntroFrames: View {
    @Binding var isCompleted: Bool
    @State private var currentFrame = 0
    
    // Settings to collect
    @State private var university = ""
    @State private var major = ""
    @State private var isInState = true  // true = in-state, false = out-of-state
    
    let universities = [
            "Penn State",
            "University of Pittsburgh",
            "Temple University",
            "Drexel University",
            "Carnegie Mellon",
            "Villanova University",
            "University of Pennsylvania",
            "Other"
        ]
        
        let majors = [
            "Computer Science",
            "Engineering",
            "Business",
            "Psychology",
            "Biology",
            "Mathematics",
            "English",
            "Political Science",
            "Economics",
            "Communications",
            "Other"
        ]
    
    var body: some View {
        ZStack {
            if currentFrame == 0 {
                // FRAME 1: Welcome
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("📚")
                        .font(.system(size: 80))
                    
                    Text("Let's Get You Set Up")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Track your tuition investment\nand never miss class")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentFrame = 1
                        }
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
            else {
                // FRAME 2: Settings
                VStack(spacing: 0) {
                    Text("Help Us Understand Your Finances")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    VStack(spacing: 45) {
                        // University Dropdown
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Text("🎓")
                                    .font(.subheadline)
                                Text("University")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Menu {
                                ForEach(universities, id: \.self) { uni in
                                    Button(uni) {
                                        university = uni
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(university.isEmpty ? "Select University" : university)
                                        .foregroundColor(university.isEmpty ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Major Dropdown
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Text("📖")
                                    .font(.subheadline)
                                Text("Major")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Menu {
                                ForEach(majors, id: \.self) { maj in
                                    Button(maj) {
                                        major = maj
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(major.isEmpty ? "Select Major" : major)
                                        .foregroundColor(major.isEmpty ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // In-State / Out-of-State Toggle
                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Text("🏠")
                                    .font(.subheadline)
                                Text("Residency")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            ZStack {
                                // Outline capsule
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.black.opacity(0.3), lineWidth: 1.2)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                                    .frame(height: 50)
                                
                                // Sliding highlight
                                HStack {
                                    if !isInState { Spacer() }
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.green)
                                        .frame(width: 160, height: 44)
                                        .animation(.easeInOut(duration: 0.25), value: isInState)
                                    if isInState { Spacer() }
                                }
                                .padding(.horizontal, 3)
                                
                                // Labels
                                HStack {
                                    Button(action: { withAnimation { isInState = true } }) {
                                        Text("In-State")
                                            .font(.headline)
                                            .foregroundColor(isInState ? .white : .gray)
                                            .frame(maxWidth: .infinity)
                                    }
                                    Button(action: { withAnimation { isInState = false } }) {
                                        Text("Out-of-State")
                                            .font(.headline)
                                            .foregroundColor(!isInState ? .white : .gray)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .frame(height: 50)
                            }
                            .frame(width: 340)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        saveSettings()
                        withAnimation {
                            isCompleted = true
                        }
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
            }

        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(university, forKey: "university")
        UserDefaults.standard.set(major, forKey: "major")
        UserDefaults.standard.set(isInState, forKey: "isInState")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        print("✅ Saved: \(university), \(major), \(isInState ? "In-State" : "Out-of-State")")
    }
}
