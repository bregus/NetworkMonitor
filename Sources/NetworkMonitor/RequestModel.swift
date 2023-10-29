import Foundation

public enum LogLevel {
  static let method: String = "log"

  case analytic(message: String)
  case debug(message: String)
  case custom(URL?)

  var title: String {
    switch self {
    case .analytic:
      return "analytic"
    case .debug:
      return "debug"
    case .custom:
      return "custom"
    }
  }
}

struct LogMessage {
  let level: LogLevel
  let label: String
  let parameters: [String: String]
  let metadata: Data
  let date = Date()

  var url: String {
    switch level {
    case .analytic(let message), .debug(let message):
      return message
    case .custom(let url):
      return url?.absoluteString ?? level.title
    }
  }
}

enum RequestType {
  case logMessage(LogMessage)
  case request(RequestModel)
}

struct RequestModel {
  enum State {
    case pending, success, failure
  }

  let id: String
  let url: String
  let host: String?
  let port: Int?
  let path: String?
  let scheme: String?
  let method: String?
  let date: Date

  var duration: Double = 0
  var error: Error? {
    didSet { state = .failure }
  }
  var state: State = .pending

  var requestHeaders: [String: String] = [:]
  var requestBody: Data?

  var code: Int = -1
  var cookies: String = ""
  var responseHeaders: [String: String] = [:]
  var responseBody: Data?

  var metrics: Metrics?

  var responseContentType: ContentType? {
    responseHeaders["Content-Type"].flatMap(ContentType.init)
  }

  public init(log: LogMessage) {
    id = UUID().uuidString
    url = log.url
    port = nil
    host = log.label
    path = nil
    method = LogLevel.method
    scheme = log.level.title
    responseHeaders = log.parameters
    responseBody = log.metadata
    date = Date()
  }

  init(request: NSURLRequest, session: URLSession?) {
    id = UUID().uuidString
    url = request.url?.absoluteString ?? ""
    host = request.url?.host
    port = request.url?.port
    path = request.url?.path
    scheme = request.url?.scheme
    date = Date()
    method = request.httpMethod ?? "GET"
    var headers = request.allHTTPHeaderFields ?? [:]
    requestBody = request.httpBody

    session?.configuration.httpAdditionalHeaders?
      .filter {  $0.0 != AnyHashable("Cookie") }
      .forEach { element in
        guard let key = element.0 as? String, let value = element.1 as? String else { return }
        headers[key] = value
      }
    self.requestHeaders = headers

    if let session = session, let url = request.url, session.configuration.httpShouldSetCookies {
      if let cookieStorage = session.configuration.httpCookieStorage,
         let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
        self.cookies = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }
      }
    }
  }

  mutating func updateWith(response: URLResponse?) {
    guard let response = response as? HTTPURLResponse else {return}
    code = response.statusCode
    responseHeaders = response.allHeaderFields.reduce(into: [String:String]()) { $0["\($1.key)"] = "\($1.value)" }
    state = (100..<400).contains(code) ? .success : .failure
  }
}
