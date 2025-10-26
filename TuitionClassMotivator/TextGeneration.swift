//
//  ContentView.swift
//  TooMuchMotion
//
//  App that displays an amount of money that corresponds to the semester tuition,
//  and the counter goes down (credit score style) when a class is missed. Class
//  misses are measured using push notifications at class time. Class times are
//  determined using AI.
//
//  Created by Sahaj on 10/25/25.
//

import SwiftUI
import Vision
import PhotosUI
import UIKit
import CoreLocation
import Foundation

struct ClassMeeting: Hashable {
    let id: String
    let name: String
    let center: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let weekday: Int
    let start: DateComponents
    let end: DateComponents
    
    static func == (lhs: ClassMeeting, rhs: ClassMeeting) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.name == rhs.name &&
                   lhs.center.latitude == rhs.center.latitude &&
                   lhs.center.longitude == rhs.center.longitude &&
                   lhs.radius == rhs.radius &&
                   lhs.weekday == rhs.weekday &&
                   lhs.start == rhs.start &&
                   lhs.end == rhs.end
    }
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(center.latitude)
            hasher.combine(center.longitude)
            hasher.combine(radius)
            hasher.combine(weekday)
            hasher.combine(start)
            hasher.combine(end)
    }
}

enum Mark { case present, absent }

final class AttendanceBinary: NSObject, CLLocationManagerDelegate {
    static let shared = AttendanceBinary()
    private let lm = CLLocationManager()
    private var today: [ClassMeeting] = []
    private var activeId: String?
    private var enterTime: Date?
    private var dwellTimer: Timer?
    private var endTimers: [String:Timer] = [:]
    var dwellRequiredSec = 1000
    var accuracyMax: CLLocationAccuracy = 50
    var speedMax: CLLocationSpeed = 8
    var leadInMin = 10, graceOutMin = 0
    var onMark: ((String, Mark)->Void)?
    
    override private init() {
        super.init(); lm.delegate = self; lm.desiredAccuracy = kCLLocationAccuracyBest; lm.allowsBackgroundLocationUpdates = true; lm.pausesLocationUpdatesAutomatically = true;
    }
    
    func configure (meetings:[ClassMeeting]) {
        scheduleToday(from: meetings); auth(); setEndTimers(); refreshRegions();
    }
    
    private func scheduleToday (from all: [ClassMeeting]) {
        let wd = Calendar.current.component(.weekday, from: Date())
        today = all.filter{$0.weekday==wd}.sorted{ Calendar.current.date(from:$0.start)! < Calendar.current.date(from:$1.start)!
        }
    }
    
    private func auth () {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined: lm.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: break
        default: break
        }
    }
    
    private func setEndTimers () {
        let cal = Calendar.current; let now = Date()
        endTimers.values.forEach{$0.invalidate()};
        endTimers.removeAll()
        for m in today {
            guard let s = cal.nextDate(after: now, matching: m.start, matchingPolicy: .nextTimePreservingSmallerComponents),
                  let e = cal.nextDate(after: now, matching: m.end, matchingPolicy: .nextTimePreservingSmallerComponents) else { continue }
            let endAt = e.addingTimeInterval(TimeInterval(60*graceOutMin))
            if endAt > now {
                let t = Timer(fire: endAt, interval: 0, repeats: false) {
                    [weak self] _ in self?.finalizeIfAbsent(m)
                }
                RunLoop.main.add(t, forMode: .common); endTimers[m.id] = t
            }
        }
    }
    
    func refreshRegions () {
        lm.monitoredRegions.forEach {
            lm.stopMonitoring(for:$0)
        }
        let cal = Calendar.current; let now = Date()
        let horizon = now.addingTimeInterval(8*3600)
        for m in today {
            guard let s = cal.nextDate(after: now, matching: m.start, matchingPolicy: .nextTimePreservingSmallerComponents),
                  let e = cal.nextDate(after: now, matching: m.end, matchingPolicy: .nextTimePreservingSmallerComponents) else { continue }
            if s <= horizon && e > now {
                let r = CLCircularRegion(center: m.center, radius: m.radius, identifier: m.id)
                r.notifyOnEntry = true; r.notifyOnExit = true; lm.startMonitoring(for:r)
            }
        }
    }
    
    private func inWindow (_ m: ClassMeeting, _ t: Date)->Bool{
        let cal = Calendar.current
        guard let s = cal.nextDate(after: t, matching: m.start, matchingPolicy: .nextTimePreservingSmallerComponents),
              let e = cal.nextDate(after: t, matching: m.end, matchingPolicy: .nextTimePreservingSmallerComponents) else { return false }
        let startGate = s.addingTimeInterval(TimeInterval(-60*leadInMin))
        let endGate = e.addingTimeInterval(TimeInterval(60*graceOutMin))
        return t >= startGate && t <= endGate
    }
    
    private func meeting(_ id: String)->ClassMeeting?{ today.first{$0.id==id} }
    
    func locationManager (_ m: CLLocationManager, didChangeAuthorization s: CLAuthorizationStatus) {
        if s == .authorizedWhenInUse || s == .authorizedAlways {
            refreshRegions()
        }
    }
    
    func locationManager (_ m: CLLocationManager, didEnterRegion r: CLRegion) {
        guard let id = (r as? CLCircularRegion)?.identifier, let cls = meeting(id) else { return }
        if inWindow(cls, Date()) {
            activeId = id; enterTime = Date(); m.requestLocation(); startDwell()
        }
    }
    
    func locationManager (_ m: CLLocationManager, didExitRegion r: CLRegion) {
        if activeId == r.identifier { stopDwell(commit:false); activeId=nil; enterTime=nil }
    }
    
    func locationManager (_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let id = activeId, let cls = meeting(id), let loc = locs.last else { return }
        if loc.horizontalAccuracy < 0 || loc.horizontalAccuracy > accuracyMax { return }
        if loc.speed > speedMax { return }
        if loc.distance(from: CLLocation(latitude: cls.center.latitude, longitude: cls.center.longitude)) > cls.radius { return }
    }
    
    func locationManager (_ m: CLLocationManager, didFailWithError e: Error) {}
    
    private func startDwell () {
        dwellTimer?.invalidate()
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {
            [weak self] _ in
            guard let s = self, let id = s.activeId, let cls = s.meeting(id), let t0 = s.enterTime else { return }
            if !s.inWindow(cls, Date()) { return }
            if Date().timeIntervalSince(t0) >= TimeInterval(s.dwellRequiredSec) { s.markPresent(cls) }
        }
    }
    
    private func stopDwell (commit: Bool) {
        dwellTimer?.invalidate()
        dwellTimer = nil
        if commit, let id = activeId, let cls = meeting(id) { markPresent(cls) }
    }
    
    private func markPresent (_ cls: ClassMeeting) {
        onMark? (cls.id, .present)
        if let r = lm.monitoredRegions.first(where:{$0.identifier==cls.id}) {
            lm.stopMonitoring(for:r)
        }
        activeId = nil; enterTime = nil; dwellTimer?.invalidate(); dwellTimer = nil
    }
    
    private func finalizeIfAbsent (_ cls: ClassMeeting) {
        onMark? (cls.id, .absent)
        if let r = lm.monitoredRegions.first(where:{$0.identifier==cls.id}) {
            lm.stopMonitoring(for:r)
        }
        if activeId == cls.id {
            activeId = nil; enterTime = nil; dwellTimer?.invalidate(); dwellTimer = nil
        }
    }
}

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var isPickerPresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .cornerRadius(12)
            }
            Text(recognizedText.isEmpty ? "No text detected" : recognizedText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            Button("Select Image") {
                isPickerPresented = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker(selectedImage: $selectedImage, recognizedText: $recognizedText)
            }
            .padding()
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("java.lang.TooMuchMotion")
        }
        .padding()
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var recognizedText: String

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = uiImage
                        detectTextFeatures(in: uiImage) { text in
                            self.parent.recognizedText = text }
                    }
                }
            }
        }
    }
}

func detectTextFeatures(in image: UIImage, completion: @escaping (String) -> Void) {
    guard let cgImage = image.cgImage else {
        completion("")
        return
    }

    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            completion("")
            return
        }
        
        // Group observations into horizontal rows
        var rows: [[VNRecognizedTextObservation]] = []
        let rowThreshold: CGFloat = 0.02 // Adjust this if needed
        
        for obs in observations {
            let obsY = obs.boundingBox.minY
            
            // Find if this observation belongs to an existing row
            var foundRow = false
            for i in 0..<rows.count {
                if let firstInRow = rows[i].first {
                    let rowY = firstInRow.boundingBox.minY
                    if abs(obsY - rowY) < rowThreshold {
                        rows[i].append(obs)
                        foundRow = true
                        break
                    }
                }
            }
            
            // If not found in any row, create a new row
            if !foundRow {
                rows.append([obs])
            }
        }
        
        // Sort rows from top to bottom (remember Y is flipped in Vision)
        rows.sort { $0[0].boundingBox.minY > $1[0].boundingBox.minY }
        
        // Within each row, sort left to right using midX for better center alignment
        for i in 0..<rows.count {
            rows[i].sort { $0.boundingBox.midX < $1.boundingBox.midX }
        }
        
        // Build text with proper spacing and line breaks
        var textLines: [String] = []
        for row in rows {
            let lineText = row
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            if !lineText.isEmpty {
                textLines.append(lineText)
            }
        }
        
        let detectedText = textLines.joined(separator: "\n")
        
        var cleaned = ""
        
        if let leftIndex = detectedText.range(of: "Enrolled")?.lowerBound,
           let rightIndex = detectedText.range(of: "Friday")?.upperBound {
            cleaned = String(detectedText[leftIndex..<rightIndex])
        }
        print(cleaned)
        
        parseClassesWithOllama(from: cleaned) {
            parsedClasses in print(parsedClasses)
        }
        DispatchQueue.main.async {
            completion(cleaned)
        }
    }

    request.recognitionLanguages = ["en-US"]
    request.recognitionLevel = .accurate

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        try? handler.perform([request])
    }
}

//func detectTextFeatures(in image: UIImage, completion: @escaping (String) -> Void) {
//    guard let cgImage = image.cgImage else {
//        completion("")
//        return
//    }
//
//    let request = VNRecognizeTextRequest { request, error in
//        guard let observations = request.results as? [VNRecognizedTextObservation] else {
//            completion("")
//            return
//        }
//        
//        let sorted = observations.sorted {
//            // First sort top to bottom (remember Vision's Y is flipped)
//            if abs($0.boundingBox.minY - $1.boundingBox.minY) > 0.02 {
//                return $0.boundingBox.minY > $1.boundingBox.minY
//            }
//            // Then sort left to right within the same line
//            return $0.boundingBox.minX < $1.boundingBox.minX
//        }
//        
//        let detectedText = sorted
//            .compactMap { $0.topCandidates(1).first?.string }
//            .joined(separator: "\n")
//        
//        var cleaned = ""
//        
//        if let leftIndex = detectedText.range(of: "Enrolled")?.lowerBound, let rightIndex = detectedText.range(of: "Friday")?.upperBound {
//            cleaned = String(detectedText[leftIndex..<rightIndex])
//        }
//        
//        let parsed = parseClassTuples(from: cleaned)
//        print(parsed)
//        DispatchQueue.main.async {
//            completion(cleaned)
//        }
//    }
//
//    request.recognitionLanguages = ["en-US"]
//    request.recognitionLevel = .accurate
//
//    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//    DispatchQueue.global(qos: .userInitiated).async {
//        try? handler.perform([request])
//    }
//}

func parseClassesWithOllama(from text: String, completion: @escaping ([(String, String, String)]) -> Void) {
    print("=== TEXT BEING SENT TO OLLAMA ===")
    print(text)
    print("=== END TEXT ===")
    
    let prompt = """
    Parse this university schedule text. Each class starts with "Enrolled" and may span multiple lines.

    Your task: Extract className, credits, startTime, and weekDays for each enrolled class.
    
    Examples from this text:
    - "Enrolled Computer Engineering... TR 3:05pm" → "Computer Engineering 331", weekDays: "TR" (2 days)
    - "Enrolled 12190 Computer 331" → "Computer Engineering 331"
    - "Enrolled 30904 Computer Science 461 003" → "Computer Science 461"
    - "Enrolled 16767 English 202C" → "English 202C"
    - "Enrolled 2000 Graphic Design 110 3" → "Graphic Design 110" with 3 credits
    - "Enrolled s 30106 Japanese 21 2" → "Japanese 21" with 2 credits
    - "Enrolled 26223 Statistics 319" → "Statistics 319"
    
    Rules for parsing:
    1. className: Subject + course number (e.g., "Computer Science 461", "English 202C")
    2. credits: Look for standalone number 2-4 near the class. If you see "4 More", that means 4 credits.
    3. startTime: First time in format like "3:05pm" or "11:15am", convert to "3:05 PM" or "11:15 AM"
    4. weekDays: Extract day codes like "MWF", "TR", "M", "F", etc. Common patterns:
       - M = Monday, T = Tuesday, W = Wednesday, R = Thursday, F = Friday
       - Count each letter as one class per week
    5. Estimate typical credits if not found: 3-credit courses for most, 2 for languages, 4 for labs
    
    The schedule text:
    \(text)
    
    Return ONLY this JSON (no other text):
    {
        "classes": [
            {"className": "Computer Engineering 331", "credits": 3, "startTime": "3:05 PM", "weekDays": "TR"},
            {"className": "Computer Engineering 331", "credits": 0, "startTime": "1:25 PM", "weekDays": "F"},
            {"className": "Computer Science 461", "credits": 3, "startTime": "11:15 AM", "weekDays": "MWF"},
            {"className": "English 202C", "credits": 3, "startTime": "1:35 PM", "weekDays": "TR"},
            {"className": "Graphic Design 110", "credits": 3, "startTime": "12:00 PM", "weekDays": "MW"},
            {"className": "Japanese 21", "credits": 2, "startTime": "2:30 PM", "weekDays": "MW"},
            {"className": "Statistics 319", "credits": 3, "startTime": "12:05 PM", "weekDays": "TR"}
        ],
        "totalCredits": 17
    }
    """
    
    let url = URL(string: "http://localhost:11434/api/generate")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let requestBody: [String: Any] = [
        "model": "llama3.2",
        "prompt": prompt,
        "stream": false,
        "format": "json",
        "options": [
            "temperature": 0.2,
            "num_predict": 1500
        ]
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    } catch {
        print("Error creating request body: \(error)")
        completion([])
        return
    }
    
    print("🔄 Sending request to Ollama...")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network error: \(error)")
            completion([])
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion([])
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseText = json["response"] as? String {
                
                print("=== AI RESPONSE ===")
                print(responseText)
                print("=== END RESPONSE ===")
                
                var jsonString = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let firstBrace = jsonString.firstIndex(of: "{"),
                   let lastBrace = jsonString.lastIndex(of: "}") {
                    let startIndex = firstBrace
                    let endIndex = jsonString.index(after: lastBrace)
                    jsonString = String(jsonString[startIndex..<endIndex])
                }
                
                print("=== EXTRACTED JSON ===")
                print(jsonString)
                print("=== END JSON ===")
                
                if let contentData = jsonString.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    let parseResponse = try decoder.decode(ClassParseResponse.self, from: contentData)
                    
                    print("✅ Successfully parsed \(parseResponse.classes.count) classes")
                    
                    guard parseResponse.totalCredits > 0 else {
                        print("⚠️ No credits detected — cost cannot be computed.")
                        completion([])
                        return
                    }
                    
                    let perCreditValue = 60000.0 / Double(parseResponse.totalCredits)
                    print("Total Credits: \(parseResponse.totalCredits)")
                    print("Per Credit Value: $\(String(format: "%.2f", perCreditValue))")
                    
                    var results: [(String, String, String)] = []
                    
                    for parsedClass in parseResponse.classes {
                        // Calculate number of classes per week based on weekDays string length
                        let classesPerWeek = parsedClass.weekDays.count
                        let totalClassesInSemester = classesPerWeek * 15
                        
                        // Calculate value per class instance
                        let totalClassValue = perCreditValue * Double(parsedClass.credits)
                        let perClassInstanceValue = totalClassValue / Double(totalClassesInSemester)
                        
                        let monetaryString = "$\(Int(perClassInstanceValue))"
                        
                        results.append((
                            parsedClass.className,
                            monetaryString,
                            parsedClass.startTime
                        ))
                        
                        print("✅ Added: \(parsedClass.className) - \(monetaryString) per class")
                        print("   Credits: \(parsedClass.credits), Days: \(parsedClass.weekDays) (\(classesPerWeek)x/week)")
                        print("   Total class value: $\(Int(totalClassValue)) / \(totalClassesInSemester) meetings = \(monetaryString)")
                    }
                    
                    DispatchQueue.main.async {
                        completion(results)
                    }
                } else {
                    print("Failed to convert content to data")
                    completion([])
                }
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("Raw response: \(dataString)")
            }
            completion([])
        }
    }
    
    task.resume()
}

// Updated struct to include weekDays
struct ClassParseResponse: Decodable {
    let classes: [ParsedClass]
    let totalCredits: Int
}

struct ParsedClass: Decodable {
    let className: String
    let credits: Int
    let startTime: String
    let weekDays: String
}

//func parseClassTuples (from text: String) -> [(String, String)] {
//    var results: [(String, String)] = []
//    var totalCredits = 0 // internal use only
//    
//    // Normalize whitespace and special characters
//    let cleaned = text
//        .replacingOccurrences(of: "\u{00A0}", with: " ")
//        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
//        .replacingOccurrences(of: "–", with: "-")
//        .trimmingCharacters(in: .whitespacesAndNewlines)
//    
//    // Class + start time extraction
//    let classPattern = #"Enrolled\s+\d+\s+([A-Za-z& ]+\d{2,3})[^\n]*?[MTWRF]+\s+(\d{1,2}:\d{2}\s?[ap]m)"#
//    
//    // Credit extraction
//    let creditPattern = #"(?:\(|\b)(\d+)\s*(?:cr|credits?)\b"#
//    
//    do {
//        // ---- Extract tuples ----
//        let classRegex = try NSRegularExpression(pattern: classPattern, options: .caseInsensitive)
//        let nsrange = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
//        
//        for match in classRegex.matches(in: cleaned, range: nsrange) {
//            if match.numberOfRanges == 3,
//               let nameRange = Range(match.range(at: 1), in: cleaned),
//               let timeRange = Range(match.range(at: 2), in: cleaned) {
//                
//                var className = cleaned[nameRange].trimmingCharacters(in: .whitespacesAndNewlines)
//                var startTime = cleaned[timeRange].trimmingCharacters(in: .whitespacesAndNewlines)
//                
//                // Add a space before AM/PM
//                startTime = startTime.replacingOccurrences(
//                    of: "(?i)(am|pm)",
//                    with: " $1",
//                    options: .regularExpression
//                ).uppercased()
//                
//                results.append((className, startTime))
//            }
//        }
//        
//        // ---- Extract total credits (internal) ----
//        let creditRegex = try NSRegularExpression(pattern: creditPattern, options: .caseInsensitive)
//        for match in creditRegex.matches(in: cleaned, range: nsrange) {
//            if match.numberOfRanges == 2,
//               let range = Range(match.range(at: 1), in: cleaned),
//               let creditValue = Int(cleaned[range]) {
//                totalCredits += creditValue
//            }
//        }
//        
//        let perCreditValue = 60000.0/Double(totalCredits)
//        
//        
//        // Optional: print, log, or use in further calculation
//        print("Total Credits Detected: \(totalCredits)")
//        
//    } catch {
//        print("Regex error:", error)
//    }
//    
//    return results
//}

#Preview {
    ContentView()
}
