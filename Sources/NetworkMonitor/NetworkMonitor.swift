import Foundation
import UIKit

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

  public func saveCustomRequest(url: URL?, data: Data?, parameters: [String: String] = [:]) {
    guard let url else { return }
    let request = RequestRepresentable(request: CustomRequest(url: url, body: data, parameters: parameters))
    Storage.shared.saveRequest(request: request)
  }
}
