import Foundation
import Combine

class ClassStackShare: ObservableObject {
    // (className, cost, time)
    @Published var attendedClasses: [(String, String, String)] = []
    @Published var missedClasses: [(String, String, String)] = []
    
    static let shared = ClassStackShare() // Single shared instance
    
    private init() {} // Prevents creating multiple instances
}
