import Foundation

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
}

extension NSNotification.Name {
  static let newRequestNotification = NSNotification.Name(rawValue: "Name.NetworkMonitorNewRequest")
}
