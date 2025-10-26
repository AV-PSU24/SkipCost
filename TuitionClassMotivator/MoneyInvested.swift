//
//  MoneyInvested.swift
//  TuitionClassMotivator
//
//  Created by Abhinav Velaga on 10/25/25.
//

import SwiftUI

struct MoneyInvested: View {
    @State private var animateStep = 0  // tracks animation stage
    let tuitionLeft = 3200.0
    let totalTuition = 6000.0
    let investedAmount = 2800.0
    var curSemester = "Fall Semester 2025"
    @ObservedObject var classData = ClassStackShare.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: 1️⃣ Header
                Group {
                    Text(curSemester)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Money Invested in Your Future")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color.green.opacity(0.8))
                }
                .opacity(animateStep >= 1 ? 1 : 0)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: animateStep)
                
                // MARK: 2️⃣ Tuition progress bar
                TuitionBarView(tuitionLeft: tuitionLeft, totalTuition: totalTuition)
                    .opacity(animateStep >= 1 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.2), value: animateStep)
                
                // MARK: 3️⃣ Investment wheel
                InvestedWheelView(investedAmount: investedAmount, totalTuition: totalTuition)
                    .opacity(animateStep >= 1 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.3), value: animateStep)
                
                // MARK: 4️⃣ Motivational message
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.green)
                    Text("Keep it up! You're building your future.")
                        .font(.footnote)
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .opacity(animateStep >= 1 ? 1 : 0)
                .animation(.easeInOut(duration: 0.3).delay(0.4), value: animateStep)
                
                // MARK: 5️⃣ Class attendance list
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Class Attendance")
                            .font(.headline)
                        Spacer()
                        Text("\(classData.attendedClasses.count)  attended")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .opacity(animateStep >= 1 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.5), value: animateStep)
                    
                    ForEach(Array(classData.attendedClasses.enumerated()), id: \.offset) { index, cls in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cls.0)
                                    .font(.subheadline)
                                    .bold()
                                Text(cls.2)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(cls.1)
                                    .foregroundColor(.green)
                                    .bold()
                                Text("invested")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        .opacity(animateStep >= 1 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).delay(0.6 + (Double(index) * 0.1)), value: animateStep)
                    }
                }
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color.white, Color(.systemGray6)],
                           startPoint: .top, endPoint: .bottom)
        )
        // re-trigger animation every time view becomes visible
        .onAppear {
            animateStep = 0
            fadeInSequence()
        }
        .onDisappear {
            animateStep = 0  // reset on exit for smooth re-entry
        }
    }
    
    // MARK: - Fade Sequence Function
    private func fadeInSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { animateStep = 1 }
    }
}

// MARK: - Components

// Tuition progress bar (green → yellow)
struct TuitionBarView: View {
    var tuitionLeft: Double
    var totalTuition: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tuition Left This Semester")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text("$\(Int(tuitionLeft)) of $\(Int(totalTuition)) left")
                    .font(.footnote)
                Spacer()
                Text("$\(Int(tuitionLeft))")
                    .font(.footnote)
                    .foregroundColor(.green)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    
                    LinearGradient(gradient: Gradient(colors: [.yellow, .green]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
                        .frame(width: geometry.size.width * (tuitionLeft / totalTuition),
                               height: 10)
                        .cornerRadius(5)
                }
            }
            .frame(height: 10)
            
        }
        .padding(.horizontal, 40)
    }
}

// Investment wheel (green → blue)
struct InvestedWheelView: View {
    var investedAmount: Double
    var totalTuition: Double
    @State private var animatedProgress: Double = 0.0   // new animated value
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(Color(.systemGray5), lineWidth: 20)
                    .rotationEffect(.degrees(180))
                
                Circle()
                    .trim(from: 0.0, to: animatedProgress * 0.5)
                    .stroke(
                        LinearGradient(
                                    gradient: Gradient(colors: [.blue, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(180))
                    .animation(.easeInOut(duration: 1.2).delay(0.3), value: animatedProgress)
                
                VStack(spacing: 4) {
                    Text("$\(Int(investedAmount))")
                        .font(.title)
                        .bold()
                        .foregroundColor(.green)
                    Text("Invested So Far")
                        .font(.headline)
                        .foregroundColor(.green.opacity(0.8))
                    Text("🤑")
                        .font(.largeTitle)
                }
                .offset(y: 45)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 140)
        }
        .padding(.horizontal)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
        .onAppear {
                // 👇 reset to zero, then animate to target
                animatedProgress = 0.0
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedProgress = investedAmount / totalTuition
                }
        }
    }
}

#Preview {
    MoneyInvested()
}
