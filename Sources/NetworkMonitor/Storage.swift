import Foundation

final class Storage: NSObject {
  static let shared: Storage = Storage()

  private(set) var requests: [RequestRepresentable] = []

  func saveRequest(request: RequestRepresentable?) {
    guard let request else { return }

    if let index = requests.firstIndex(where: { request.id == $0.id }) {
      requests[index] = request
    } else {
      requests.insert(request, at: 0)
    }
    NotificationCenter.default.post(name: NSNotification.Name.NewRequestNotification, object: nil)
  }

  func clearRequests() {
    requests.removeAll()
    NotificationCenter.default.post(name: NSNotification.Name.NewRequestNotification, object: nil)
  }
}

extension NSNotification.Name {
  static let NewRequestNotification = NSNotification.Name(rawValue: "Name.NetShearsNewRequest")
}
