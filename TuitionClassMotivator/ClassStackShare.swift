import Foundation
import Combine

class ClassStackShare: ObservableObject {
    // (className, cost, time)
    @Published var attendedClasses: [(String, String, String)] = []
    @Published var missedClasses: [(String, String, String)] = []
    @Published var classSchedule: [(String, String, String)] = []
    
    //global vars
    @Published var university: String = ""
    @Published var major: String = ""
    @Published var isInState: Bool = true
    @Published var semesterTuition: Double = 15000.0
    @Published var investmentSum: Double = 0.0
    @Published var LostSum: Double = 0.0

    static let shared = ClassStackShare() // Single shared instance
    
    private init() {} // Prevents creating multiple instances
}
