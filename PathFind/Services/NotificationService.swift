import Foundation
import UIKit
import UserNotifications

@Observable
class NotificationService: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationService()

  var isAuthorized: Bool = false
  var pendingReminders: [String: Date] = [:]

  private override init() {
    super.init()
    UNUserNotificationCenter.current().delegate = self
    Task {
      await checkAuthorizationStatus()
      await refreshPendingReminders()
    }
  }

  func requestAuthorization() async {
    do {
      let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [
        .alert, .sound, .badge,
      ])
      await MainActor.run {
        self.isAuthorized = granted
      }
    } catch {
      print("Failed to request notification authorization: \(error)")
    }
  }

  func checkAuthorizationStatus() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    await MainActor.run {
      self.isAuthorized = settings.authorizationStatus == .authorized
    }
  }

  func scheduleReminder(for bookmarkId: String, url: String, title: String, at date: Date) async {
    if !isAuthorized {
      await requestAuthorization()
      if !isAuthorized { return }
    }

    let content = UNMutableNotificationContent()
    content.title = "Bookmark Reminder"
    content.body = "Time to revisit: \(title)"
    content.sound = .default
    // We can store the bookmarkId in userInfo to handle deep linking later if needed
    content.userInfo = ["bookmarkId": bookmarkId, "url": url]

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let request = UNNotificationRequest(identifier: bookmarkId, content: content, trigger: trigger)

    do {
      try await UNUserNotificationCenter.current().add(request)
      await refreshPendingReminders()
    } catch {
      print("Failed to schedule reminder: \(error)")
    }
  }

  func cancelReminder(for bookmarkId: String) async {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      bookmarkId
    ])
    await refreshPendingReminders()
  }

  func refreshPendingReminders() async {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    var newPending: [String: Date] = [:]

    for request in requests {
      if let trigger = request.trigger as? UNCalendarNotificationTrigger,
        let nextTriggerDate = trigger.nextTriggerDate()
      {
        newPending[request.identifier] = nextTriggerDate
      }
    }

    await MainActor.run {
      self.pendingReminders = newPending
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  // Allow showing notifications when the app is in the foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    return [.banner, .sound]
  }

  // Handle interaction with the notification
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let urlString = userInfo["url"] as? String, let url = URL(string: urlString) {
      DispatchQueue.main.async {
        UIApplication.shared.open(url)
      }
    }
    completionHandler()
  }
}
