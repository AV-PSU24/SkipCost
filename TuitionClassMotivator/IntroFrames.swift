import SwiftUI

struct IntroFrames: View {
    @Binding var isCompleted: Bool
    @State private var currentFrame = 0
    
    // Settings to collect
    
    @StateObject private var classStack = ClassStackShare.shared

    @State private var selectedImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var isPickerPresented = false
    @State private var isLoadingClasses = false

    
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
            else if currentFrame == 1 {
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
                                        classStack.university = uni
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(classStack.university.isEmpty ? "Select University" : classStack.university)
                                        .foregroundColor(classStack.university.isEmpty ? .gray : .primary)
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
                                        classStack.major = maj
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(classStack.major.isEmpty ? "Select Major" : classStack.major)
                                        .foregroundColor(classStack.major.isEmpty ? .gray : .primary)
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
                                    if !classStack.isInState { Spacer() }
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.green)
                                        .frame(width: 160, height: 44)
                                        .animation(.easeInOut(duration: 0.25), value: classStack.isInState)
                                    if classStack.isInState { Spacer() }
                                }
                                .padding(.horizontal, 3)
                                
                                // Labels
                                HStack {
                                    Button(action: { withAnimation { classStack.isInState = true } }) {
                                        Text("In-State")
                                            .font(.headline)
                                            .foregroundColor(classStack.isInState ? .white : .gray)
                                            .frame(maxWidth: .infinity)
                                    }
                                    Button(action: { withAnimation { classStack.isInState = false } }) {
                                        Text("Out-of-State")
                                            .font(.headline)
                                            .foregroundColor(!classStack.isInState ? .white : .gray)
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
                        saveBasicSettings()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentFrame = 2
                        }
                    }) {
                        Text("Next")
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
                // FRAME 3: Upload Schedule
                VStack(spacing: 20) {
                    Text("📅")
                        .font(.system(size: 60))
                        .padding(.top, 40)
                    
                    Text("Upload Your Schedule")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(12)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if classStack.classSchedule.isEmpty {
                                VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                            .scaleEffect(1.5)
                                        
                                        Text("Performing AI Analysis...")
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            else {
                                ForEach(classStack.classSchedule.indices, id: \.self) { index in
                                    let classInfo = classStack.classSchedule[index]
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(classInfo.0) // Class name
                                            .font(.headline)
                                        Text("Cost: $\(classInfo.1)") // Cost
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Time: \(classInfo.2)") // Time
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if index < classStack.classSchedule.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding()
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxHeight: 150)
                    
                    Button("Select Schedule Image") {
                        isPickerPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $isPickerPresented) {
                        PhotoPicker(selectedImage: $selectedImage, recognizedText: $recognizedText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        saveSettings()
                        withAnimation {
                            isCompleted = true
                        }
                    }) {
                        Text(classStack.classSchedule.isEmpty ? "Skip for Now" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(classStack.classSchedule.isEmpty ? Color.gray : Color.green)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
                .padding()
                .transition(.opacity)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func saveBasicSettings() {
        UserDefaults.standard.set(classStack.university, forKey: "university")
        UserDefaults.standard.set(classStack.major, forKey: "major")
        UserDefaults.standard.set(classStack.isInState, forKey: "isInState")
    }
    
    private func saveSettings() {
        saveBasicSettings()
        UserDefaults.standard.set(recognizedText, forKey: "scheduleText")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        print("✅ Saved: \(classStack.university), \(classStack.major), \(classStack.isInState ? "In-State" : "Out-of-State")")
    }
}
