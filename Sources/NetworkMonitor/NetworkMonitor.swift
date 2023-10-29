import Foundation
import UIKit

public struct NetworkMonitor {
  public static func startListener() {
    URLProtocol.registerClass(NetwrokListenerUrlProtocol.self)
  }

  public static func stopListener() {
    URLProtocol.unregisterClass(NetwrokListenerUrlProtocol.self)
  }

  public static func presentNetworkMonitor() {
    guard let topController = UIViewController.currentViewController(), !(topController is RequestsViewController) else { return }
    topController.present(RequestsViewController().embended, animated: true)
  }

  public static func log(
    level: LogLevel,
    label: String,
    parameters: [String: String] = [:],
    metadata: Data = Data(),
    file: String = #fileID,
    method: String = #function,
    line: UInt = #line
  ) {
    let fileDetails = ["File name": file.description + UInt(line).description, "Function": method]
    let log = LogMessage(level: level, label: label, parameters: parameters.merging(fileDetails, uniquingKeysWith: { $1 }), metadata: metadata)
    Storage.shared.saveRequest(request: RequestModel(log: log))
  }
}
