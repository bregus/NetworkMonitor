import Foundation
import UIKit

public enum LogLevel: String {
  case analytic
}

public struct NetworkMonitor {
  public static let shared = NetworkMonitor()

  public func startListener() {
    URLProtocol.registerClass(NetwrokListenerUrlProtocol.self)
  }

  public func stopListener() {
    URLProtocol.unregisterClass(NetwrokListenerUrlProtocol.self)
  }

  @available(iOS 14, *)
  public func presentNetworkMonitor() {
    guard let topController = UIViewController.currentViewController(), !(topController is RequestsViewController) else { return }
    topController.present(RequestsViewController().embended, animated: true)
  }

  public func custom(url: URL?, data: Data? = nil, parameters: [String: String] = [:]) {
    guard let url else { return }
    var request = RequestRepresentable(request: CustomRequest(url: url, body: data, parameters: parameters))
    request.isFinished = true
    Storage.shared.saveRequest(request: request)
  }

  public func log(level: LogLevel, message: String, parameters: [String: String] = [:], metadata: Data = Data()) {
    guard let url = URL(string: level.rawValue + "://" + message) else { return }
    let request = RequestRepresentable(request: CustomRequest(url: url, body: metadata, parameters: parameters))
    Storage.shared.saveRequest(request: request)
  }
}
