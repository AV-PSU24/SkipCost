import Foundation
import Combine
import UserNotifications

/// Global timer manager that periodically checks class times and sends local notifications
final class NotificationTimer: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private var timer: Timer?

    // MARK: - Init
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self  // Set delegate
        requestNotificationPermission()
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Timer Control
    @MainActor
    func startTimer(with classSchedule: [(String, String)]) {
        stopTimer() // Stop any old timers
        print("⏰ Notification timer started — checking every 5 minutes")

        // Run once immediately
        checkForMatchingClasses(classSchedule: classSchedule)

        // Repeat every 1 minutes (60 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                self.checkForMatchingClasses(classSchedule: classSchedule)
            }
        }

        if let timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        print("🛑 Notification timer stopped")
    }

    // MARK: - Check Logic
    @MainActor
    private func checkForMatchingClasses(classSchedule: [(String, String)]) {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy, h:mm a"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let currentString = formatter.string(from: now)
        //print("Checking for classes at \(currentString)")

        for (className, timeString) in classSchedule {
            //print("Current time: \(formatter.string(from: now))")  // Add this line
            
            if let classTime = formatter.date(from: timeString) {
                let diff = abs(classTime.timeIntervalSince(now))
                //print("\(className)")
                //print("   Scheduled: \(timeString)")
                //print("   Parsed to: \(classTime)")
                //print("   Diff: \(diff) seconds (\(diff/3600) hours)")  // Show hours too
                
                if diff < 60 {
                    //print("MATCH! Sending notification")
                    sendNotification(for: className)
                } else {
                    //print("Not within 60 seconds")
                }
            } else {
                //print("Failed to parse: \(timeString)")
            }
        }
    }

    // MARK: - Notifications

    private func sendNotification(for className: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎓 Class Reminder"
        content.body = "It's time for \(className)! Don’t miss it."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
        print("📢 Notification sent for \(className)")
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
}
