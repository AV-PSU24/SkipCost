//
//  MoneyWasted.swift
//  TuitionClassMotivator
//
//  Created by Abhinav Velaga on 10/25/25.
//

import SwiftUI

struct MoneyWasted: View {
    @State private var animateStep = 0  // tracks animation stage
    let tuitionLeft = 3200.0
    let totalTuition = 6000.0
    let wastedAmount = 2000.0
    var curSemester = "Fall Semester 2025"
    let missedClasses = [
        ("STAT 200 – Statistics", "-$24", "Nov 18, 9:00 AM"),
        ("PSYCH 100 – Intro to Psych", "-$30", "Nov 20, 11:00 AM"),
        ("PSYCH 100 – Intro to Psych", "-$30", "Nov 20, 11:00 AM"),
        ("PSYCH 100 – Intro to Psych", "-$30", "Nov 20, 11:00 AM"),
        ("PSYCH 100 – Intro to Psych", "-$30", "Nov 20, 11:00 AM"),
        ("PSYCH 100 – Intro to Psych", "-$30", "Nov 20, 11:00 AM"),
        ("PSYCH 100 – Intro to Psych", "-$30", "Nov 20, 11:00 AM")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                Group{
                    Text(curSemester)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Money Lost by Missing Class")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color.red.opacity(0.8))
                }
                .opacity(animateStep >= 1 ? 1 : 0)
                .animation(.easeInOut(duration: 0.3).delay(0.1), value: animateStep)
                // Tuition progress bar
                TuitionBarView(tuitionLeft: tuitionLeft, totalTuition: totalTuition)
                    .opacity(animateStep >= 1 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.2), value: animateStep)
                
                // Wasted money wheel
                WastedWheelView(wastedAmount: wastedAmount, totalTuition: totalTuition)
                    .opacity(animateStep >= 1 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.3), value: animateStep)
                
                // Warning message
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Each missed class costs you real money!")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .opacity(animateStep >= 1 ? 1 : 0)
                .animation(.easeInOut(duration: 0.3).delay(0.4), value: animateStep)
                
                // Missed classes list
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Missed Classes")
                            .font(.headline)
                        Spacer()
                        Text("\(missedClasses.count) absences")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .opacity(animateStep >= 1 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.5), value: animateStep)
 
                    ForEach(Array(missedClasses.enumerated()), id: \.offset) { index, cls in
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
                                    .foregroundColor(.red)
                                    .bold()
                                Text("lost")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        .opacity(animateStep >= 1 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).delay(0.6 + Double(index) * 0.1), value: animateStep)
                    }
                }
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color.white, Color(.systemGray6)],
                           startPoint: .top, endPoint: .bottom)
        )
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

// MARK: - Wasted wheel
struct WastedWheelView: View {
    var wastedAmount: Double
    var totalTuition: Double
    @State private var animatedProgress: Double = 0.0   // 👈 new animated value
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // background semi-circle
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(Color(.systemGray5), lineWidth: 20)
                    .rotationEffect(.degrees(180))
                
                // progress semi-circle
                Circle()
                    .trim(from: 0.0, to: animatedProgress * 0.5)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(180))
                    .animation(.easeInOut(duration: 1.2).delay(0.3), value: animatedProgress)

                // text block
                VStack(spacing: 4) {
                    Text("$\(Int(wastedAmount))")
                        .font(.title)
                        .bold()
                        .foregroundColor(.red)
                    Text("Lost")
                        .font(.headline)
                        .foregroundColor(.red.opacity(0.8))
                    Text("😭")
                        .font(.largeTitle)

                }
                .offset(y: 45)
            }
            // Ensures the ZStack fills available width, centers internally
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 140)
        }
        .padding(.horizontal)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity) // Centers the entire wheel container
        .onAppear {
                // reset to zero, then animate to target
                animatedProgress = 0.0
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedProgress = wastedAmount / totalTuition
                }
        }
    }
    
}

#Preview {
    MoneyWasted()
}
