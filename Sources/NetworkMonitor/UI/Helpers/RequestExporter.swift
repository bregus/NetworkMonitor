import Foundation

final class RequestExporter {
  static func txtExport(request: RequestModel, short: Bool = false) -> NSAttributedString {
    guard request.method != LogLevel.method else { return logExport(request: request) }
    let txt = NSMutableAttributedString()
    txt.append("Overview\n".header())
    txt.append(overview(request: request))
    txt.append("\n".value())
    if !short {
      txt.append("Request Headers\n".header())
      txt.append(header(request.requestHeaders))
      txt.append("\n".value())
      txt.append("Request Body\n".header())
      txt.append(body(request.requestBody))
      txt.append("\n\n".value())
      txt.append("Response Headers\n".header())
      txt.append(header(request.responseHeaders))
      txt.append("\n".value())
    }
    txt.append("Response Body\n".header())
    if let contentType = request.responseContentType {
      txt.append(contentType.isJSON ? body(request.responseBody) : contentType.rawValue.value())
    } else {
      txt.append("-".value())
    }
    txt.append("\n\n".value())
    return txt
  }

  static func curlExport(request: RequestModel) -> String? {
    guard request.host != nil else { return nil }
    var components = ["curl -v"]

    if let method = request.method, method != "GET" {
      components.append("-X \(method)")
    }
    components += request.requestHeaders.map {
      let escapedValue = String(describing: $0.value).replacingOccurrences(of: "\"", with: "\\\"")
      return "-H \"\($0.key): \(escapedValue)\""
    }

    if let httpBodyData = request.requestBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
      var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
      escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
      components.append("-d \"\(escapedBody)\"")
    }
    components.append("\"\(request.url)\"")
    return components.joined(separator: " \\\n\t")
  }

  static func logExport(request: RequestModel) -> NSAttributedString {
    let text = NSMutableAttributedString()
    var overview = [(String, String)]()
    if let scheme = request.scheme {
      overview.append((scheme.uppercased(), request.path ?? request.url))
    }
    overview.append(("Date", request.date.stringWithFormat(dateFormat: "HH:mm:ss")!))

    text.append(.render(overview))
    text.append("\n".value())
    text.append("Parameters\n".header())
    text.append(header(request.responseHeaders))
    text.append("\n".value())
    text.append("Metadata\n".header())
    text.append(body(request.responseBody))
    return text
  }

  static func overview(request: RequestModel) -> NSAttributedString {
    var overview: [String: String] = [:]
    overview["Date"] = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
    overview["URL"] = request.url
    if let method =  request.method { overview["Method"] = method }
    if request.code != -1 {
      overview["Response code"] = StatusCodeFormatter.string(for: request.code)
    } else {
      overview["Error"] = ErrorFormatter.shortErrorDescription(for: request)
    }
    if request.duration != 0 { overview["Duration"] = request.duration.formattedMilliseconds }

    return .render(overview.sorted(by: >).map {($0.key, $0.value)})
  }

  static func header(_ headers: [String: String]?) -> NSAttributedString {
    guard let headers, !headers.isEmpty else { return "-\n".value() }
    return .render(headers.sorted(by: >).map {($0.key, $0.value)})
  }

  static func body(_ body: Data?) -> NSAttributedString {
    guard let body, !body.isEmpty else { return "-".value() }
    return .render(body)
  }
}

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
