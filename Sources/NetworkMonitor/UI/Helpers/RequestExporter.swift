import Foundation

final class RequestExporter {
  static func txtExport(request: RequestModel, short: Bool = false) -> NSAttributedString {
    guard request.method != LogLevel.method else { return logExport(request: request) }
    let txt = NSMutableAttributedString()
    txt.append("Overview\n".header())
    txt.append(overview(request: request))
    txt.append("\n".value())
    if !short {
      txt.append("Cookies\n".header())
      txt.append((request.cookies.isEmpty ? "-" : request.cookies).value())
      txt.append("\n\n".value())
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

    return .render(overview.sorted(by: >).map { ($0.key, $0.value) })
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
