import Foundation
import UserNotifications

enum FilterType: String, CaseIterable {
  typealias Filter = () -> [RequestModel]
  case network
  case log
  case all

  var filter: Filter {
    switch self {
    case .network:
      return { Storage.shared.requests.filter{ $0.method != LogLevel.method } }
    case .log:
      return { Storage.shared.requests.filter{ $0.method == LogLevel.method } }
    case .all:
      return { Storage.shared.requests }
    }
  }
}

final class Storage {
  static let shared: Storage = Storage()

  var requests: [RequestModel] {
    get { _requests.wrappedValue }
  }

  private var _requests = Protected<[RequestModel]>([])

  func saveRequest(request: RequestModel?) {
    guard let request else { return }
    if let index = requests.firstIndex(where: { request.id == $0.id }) {
      _requests.write { $0[index] = request }
    } else {
      sendNotification()
      _requests.write { $0.insert(request, at: 0) }
    }

    NotificationCenter.default.post(name: .newRequestNotification, object: nil)
  }

  func clearRequests() {
    _requests.write { $0.removeAll() }
    NotificationCenter.default.post(name: .newRequestNotification, object: nil)
  }

  func deleteRequest(_ request: RequestModel) {
    guard let index = requests.firstIndex(where: { $0 == request }) else { return }
    _requests.write { $0.remove(at: index) }
    NotificationCenter.default.post(name: .newRequestNotification, object: nil)
  }

  func sendNotification() {
    UNUserNotificationCenter.current().getDeliveredNotifications { requests in
      guard requests.isEmpty else { return }
      let content = UNMutableNotificationContent()
      content.title = "🤖 New Request Recieved"
      content.categoryIdentifier = "monitor"
      let request = UNNotificationRequest(identifier: "com.bregus.networkMonitor", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request)
    }
  }
}

extension NSNotification.Name {
  static let newRequestNotification = NSNotification.Name(rawValue: "Name.NetworkMonitorNewRequest")
}
