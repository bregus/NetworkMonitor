import Foundation
import UserNotifications

final class Storage: NSObject {
  static let shared: Storage = Storage()

  private(set) var requests: [RequestRepresentable] = []

  func saveRequest(request: RequestRepresentable?) {
    guard let request else { return }

    if let index = requests.firstIndex(where: { request.id == $0.id }) {
      requests[index] = request
    } else {
      showNotification()
      requests.insert(request, at: 0)
    }

    NotificationCenter.default.post(name: NSNotification.Name.NewRequestNotification, object: nil)
  }

  func clearRequests() {
    requests.removeAll()
    NotificationCenter.default.post(name: NSNotification.Name.NewRequestNotification, object: nil)
  }

  func showNotification() {
    UNUserNotificationCenter.current().getDeliveredNotifications { requests in
      guard requests.isEmpty else { return }
      let content = UNMutableNotificationContent()
      content.title = "New Request Recieved"
      content.categoryIdentifier = "monitor"
      content.userInfo["category"] = "monitor"
      let request = UNNotificationRequest(identifier: "com.bregus.networkMonitor", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request)
    }
  }
}

extension NSNotification.Name {
  static let NewRequestNotification = NSNotification.Name(rawValue: "Name.NetShearsNewRequest")
}
