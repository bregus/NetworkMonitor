import Foundation
import UserNotifications

@propertyWrapper
struct Atomic<Value> {
  private let queue = DispatchQueue(label: "com.bregus.networkMonitor")
  private var value: Value

  init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  var wrappedValue: Value {
    get { return queue.sync { value } }
    set { queue.sync { value = newValue } }
  }
}

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

final class Storage: NSObject {
  static let shared: Storage = Storage()

  @Atomic private(set) var requests: [RequestModel] = []

  func saveRequest(request: RequestModel?) {
    guard let request else { return }

    if let index = requests.firstIndex(where: { request.id == $0.id }) {
      requests[index] = request
    } else {
      showNotification()
      requests.insert(request, at: 0)
    }

    NotificationCenter.default.post(name: NSNotification.Name.NewRequestNotification, object: nil)
  }

  func updateRequestError(id: String, error: Error) {
    guard let index = requests.firstIndex(where: { id == $0.id }) else { return }
    requests[index].error = error
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
  static let NewRequestNotification = NSNotification.Name(rawValue: "Name.NetworkMonitorNewRequest")
}
