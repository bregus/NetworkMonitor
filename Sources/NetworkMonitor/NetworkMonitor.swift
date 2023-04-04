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

  public func presentNetworkMonitor() {
    UIViewController.currentViewController()?.present(RequestsViewController().embended, animated: true)
  }
}
