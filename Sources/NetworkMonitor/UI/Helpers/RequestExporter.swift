import Foundation

final class RequestExporter {
  static func txtExport(request: RequestModel) -> NSAttributedString {
    let txt = NSMutableAttributedString()
    txt.append("Overview\n".header())
    txt.append(overview(request: request))
    txt.append("\n\n".value())
    txt.append("Request Header\n".header())
    txt.append(header(request.requestHeaders))
    txt.append("\n\n".value())
    txt.append("Request Body\n".header())
    txt.append(body(request.requestBody))
    txt.append("\n\n".value())
    txt.append("Response Header\n".header())
    txt.append(header(request.responseHeaders))
    txt.append("\n\n".value())
    txt.append("Response Body\n".header())
    if let contentType = request.responseContentType {
      txt.append(contentType.isJSON ? body(request.responseBody) : contentType.rawValue.value())
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

  private static func overview(request: RequestModel) -> NSAttributedString {
    var overview: [String: String] = [:]
    overview["Date"] = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
    overview["URL"] = request.url
    if let method =  request.method { overview["Method"] = method }
    if request.code != -1 { overview["Response code"] = StatusCodeFormatter.string(for: request.code) }
    if request.duration != 0 { overview["Duration"] = request.duration.formattedMilliseconds }

    return overview
      .sorted(by: >)
      .reduce(into: NSMutableAttributedString()) { partialResult, elem in
        partialResult.append("\(elem.key): ".key())
        partialResult.append("\(elem.value)\n".value())
      }
  }

  private static func header(_ headers: [String: String]?) -> NSAttributedString {
    guard let headers, !headers.isEmpty else { return "-\n".value() }
    return headers.reduce(into: NSMutableAttributedString()) { partialResult, elem in
      partialResult.append("\(elem.key): ".key())
      partialResult.append("\(elem.value)\n".value())
    }
  }

  private static func body(_ body: Data?) -> NSAttributedString {
    guard let body else { return "-\n".value() }
    return .render(try? JSONSerialization.jsonObject(with: body, options: []))
  }
}
