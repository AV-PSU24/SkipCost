import Foundation
import Combine
import UserNotifications
import UniformTypeIdentifiers

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
        
        //NOW send to either MoneyInvested or MoneyWasted stack
        
        guard let className = notification.request.content.userInfo["className"] as? String,
              let classCost = notification.request.content.userInfo["classCost"] as? String else {
                return
        }
        
        
        //short time format "hh"mm AM/PM"
        let currentTime = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        let attended = true
        
        if attended {
            ClassStackShare.shared.attendedClasses.append((className, classCost, currentTime))
            //print("Added to Money Invested: \(className)")
        }
        else {
            ClassStackShare.shared.missedClasses.append((className,classCost, currentTime))
            //print("Added to Money Wasted: \(className)")
        }
    
    }

    // MARK: - Timer Control
    @MainActor
    func startTimer(with classSchedule: [(String, String, String)]) {
        stopTimer() // Stop any old timers

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
    }

    // MARK: - Check Logic
    @MainActor
    private func checkForMatchingClasses(classSchedule: [(String, String,String)]) {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")

        //let currentString = formatter.string(from: now)
        // Get current hour and minute
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        guard let nowHour = nowComponents.hour, let nowMinute = nowComponents.minute else { return }

        for (className,classCost, timeString) in classSchedule {
            if let classTime = formatter.date(from: timeString) {
                // Get class hour and minute
                let classComponents = calendar.dateComponents([.hour, .minute], from: classTime)
                guard let classHour = classComponents.hour, let classMinute = classComponents.minute else { continue }
                
                // Calculate difference in minutes only
                let nowTotalMinutes = nowHour * 60 + nowMinute
                let classTotalMinutes = classHour * 60 + classMinute
                let diffMinutes = abs(nowTotalMinutes - classTotalMinutes)
                
                //print("Current time: \(currentString)")
                //print("\(className)")
                //print("Scheduled: \(timeString)")
                //print("Diff: \(diffMinutes) minutes")
                
                if diffMinutes <= 1 { // within 1 minute
                    //print("Sending notification")
                    sendNotification(for: className,cost: classCost)
                }
                else {
                    //print("Not within 1 minute")
                }
            }
        }
    }

    // MARK: - Notifications

    private func sendNotification(for className: String, cost: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎓 Class Reminder"
        content.body = "It's time for \(className)! Don’t miss it."
        content.sound = .default
        content.userInfo = [
                "className": className,
                "classCost": cost
        ]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            /*if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }*/
        }
    }
}
