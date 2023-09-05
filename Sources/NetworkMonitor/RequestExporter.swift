import Foundation

final class RequestExporter {
  static func txtExport(request: RequestModel) -> String{
    var txt: String = ""
    txt.append("*** Overview *** \n\n")
    txt.append(overview(request: request) + "\n\n")
    txt.append("*** Request Header *** \n")
    txt.append(header(request.requestHeaders) + "\n\n")
    txt.append("*** Request Body *** \n")
    txt.append(body(request.requestBody) + "\n\n")
    txt.append("*** Response Header *** \n")
    txt.append(header(request.responseHeaders) + "\n\n")
    txt.append("*** Response Body *** \n")
    txt.append(body(request.responseBody) + "\n\n")
    return txt
  }

  private static func overview(request: RequestModel) -> String {
    var overview: [String: String] = [:]
    overview["Date"] = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
    overview["URL"] = request.url
    if let method =  request.method { overview["Method"] = method }
    if request.code != -1 { overview["Response code"] = StatusCodeFormatter.string(for: request.code) }
    if request.duration != 0 { overview["Duration"] = request.duration.formattedMilliseconds }
    if let errorClientDescription = request.errorClientDescription as? NSError {
      overview["URLError Description"] = errorClientDescription.description
    }

    return overview
      .sorted(by: >)
      .reduce(into: String()) { partialResult, elem in
        partialResult += "\(elem.key): \(elem.value)\n\n"
      }
  }

  private static func header(_ headers: [String: String]?) -> String {
    guard let headers, !headers.isEmpty else { return "-" }
    return headers.reduce(into: String()) { partialResult, elem in
      partialResult += "\(elem.key): \(elem.value)\n"
    }
  }

  private static func body(_ body: Data?) -> String {
    guard let body else { return "-" }
    return body.prettyPrintedJSONString ?? "-"
  }
}
