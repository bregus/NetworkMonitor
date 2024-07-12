//
//  MetricsExporter.swift
//
//
//  Created by Roma Sumorokov on 12.07.2024.
//

import Foundation

final class MetricsExporter {
  static func transactionDetail(metrics: Metrics) -> NSAttributedString {
    let text = NSMutableAttributedString()
    metrics.transactions.forEach {
      text.append(RequestExporter.overview(request: $0.request))
      text.append("\n".key())
      text.append(transferSizes(metrics: $0))
      text.append("\n".key())
      text.append(protocolFrom(metrics: $0))
      text.append("\n".key())
      text.append(makeTiming(for: $0))
      text.append("\n".key())
      text.append(conditions(metrics: $0))
      text.append("\n\n".key())
    }
    return text
  }

  private static func transferSizes(metrics: TransactionMetrics) -> NSAttributedString {
    var items = [(String, String)]()
    items.append(("Fetch Type", metrics.fetchType.title + "\n"))
    
    items.append(("Request Headers", metrics.transferSize.requestHeaderBytesSent.byteCount))
    items.append(("Request Body", metrics.transferSize.requestBodyBytesSent.byteCount))
    items.append(("Request Body (Encoded)", metrics.transferSize.requestBodyBytesBeforeEncoding.byteCount + "\n"))

    items.append(("Response Headers", metrics.transferSize.responseHeaderBytesReceived.byteCount))
    items.append(("Response Body", metrics.transferSize.responseBodyBytesReceived.byteCount))
    items.append(("Response Body (Decoded)", metrics.transferSize.responseBodyBytesAfterDecoding.byteCount))

    let result = NSMutableAttributedString()
    result.append("Data Transfer\n".header())
    result.append(.render(items))
    return result
  }

  private static func protocolFrom(metrics: TransactionMetrics) -> NSAttributedString {
    var items = [(String, String)]()

    items.append(("Network Protocol", metrics.networkProtocol ?? ""))
    items.append(("Remote Address", metrics.remoteAddress ?? ""))
    if let remotePort = metrics.remotePort, remotePort > 0 {
      items.append(("Remote Port", String(remotePort)))
    }
    items.append(("Local Address", metrics.localAddress ?? ""))
    if let localPort = metrics.localPort, localPort > 0 {
      items.append(("Local Port", String(localPort)))
    }

    let result = NSMutableAttributedString()
    result.append("Protocol\n".header())
    result.append(.render(items))
    return result
  }

  private static func conditions(metrics: TransactionMetrics) -> NSAttributedString {
    var items = [(String, String)]()
    items.append(("Cellular", metrics.conditions.isCellular.description))
    items.append(("Expensive", metrics.conditions.isExpensive.description))
    items.append(("Constrained", metrics.conditions.isConstrained.description))
    items.append(("Proxy Connection", metrics.conditions.isProxyConnection.description))
    items.append(("Reused Connection", metrics.conditions.isReusedConnection.description))
    items.append(("Multipath", metrics.conditions.isMultipath.description))

    let result = NSMutableAttributedString()
    result.append("Conditions\n".header())
    result.append(.render(items))
    return result
  }

  private static func makeTiming(for transaction: TransactionMetrics) -> NSAttributedString {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "hh:mm:ss.SSS"

    var startDate: Date?
    var items: [(String, String)] = []
    func addDate(_ date: Date?, title: String) {
      guard let date = date else { return }
      if items.isEmpty {
        startDate = date
      }
      var value = timeFormatter.string(from: date)
      if let startDate = startDate, startDate != date {
        let duration = date.timeIntervalSince(startDate)
        value += " (+\(DurationFormatter.string(from: duration)))"
      }
      items.append((title, value))
    }
    let timing = transaction.timing
    addDate(timing.fetchStartDate, title: "Fetch Start")
    addDate(timing.domainLookupStartDate, title: "Domain Lookup Start")
    addDate(timing.domainLookupEndDate, title: "Domain Lookup End")
    addDate(timing.connectStartDate, title: "Connect Start")
    addDate(timing.secureConnectionStartDate, title: "Secure Connect Start")
    addDate(timing.secureConnectionEndDate, title: "Secure Connect End")
    addDate(timing.connectEndDate, title: "Connect End")
    addDate(timing.requestStartDate, title: "Request Start")
    addDate(timing.requestEndDate, title: "Request End")
    addDate(timing.responseStartDate, title: "Response Start")
    addDate(timing.responseEndDate, title: "Response End")
    let result = NSMutableAttributedString()
    result.append("Timings\n".header())
    result.append(.render(items))
    return result
  }
}

enum DurationFormatter {
  static func string(from timeInterval: TimeInterval) -> String {
    string(from: timeInterval, isPrecise: true)
  }

  static func string(from timeInterval: TimeInterval, isPrecise: Bool) -> String {
    if timeInterval < 0.95 {
      if isPrecise {
        return String(format: "%.1f ms", timeInterval * 1000)
      } else {
        return String(format: "%.0f ms", timeInterval * 1000)
      }
    }
    if timeInterval < 200 {
      return String(format: "%.\(isPrecise ? "3" : "1")f s", timeInterval)
    }
    let minutes = timeInterval / 60
    if minutes < 60 {
      return String(format: "%.1f min", minutes)
    }
    let hours = timeInterval / (60 * 60)
    return String(format: "%.1f h", hours)
  }
}

extension URLSessionTaskMetrics.ResourceFetchType {
    var title: String {
        switch self {
        case .networkLoad: return "Network Load"
        case .localCache: return "Cache Lookup"
        case .serverPush: return "Server Push"
        case .unknown: return "Unknown Fetch Type"
        default: return "Unknown Fetch Type"
        }
    }
}
