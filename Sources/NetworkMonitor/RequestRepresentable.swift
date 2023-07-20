import Foundation

public struct CustomRequest {
  let url: URL
  let body: Data?
  let parameters: [String: String]
}

public struct RequestRepresentable {
  let id: String
  let url: String
  let host: String?
  let port: Int?
  let path: String?
  let scheme: String?
  let method: String?
  var code: Int? = nil
  let date: Date

  var error: Error? = nil
  var duration: Double?
  var errorClientDescription: Error? = nil
  var isFinished: Bool

  var requestHeaders: [String: String] = [:]
  var requestBody: Data?
  var responseHeaders: [String: String] = [:]
  var responseBody: Data? = nil

  public init(request: CustomRequest) {
    id = UUID().uuidString
    url = request.url.absoluteString
    port = request.url.port
    host = request.url.host
    path = request.url.path
    method = request.url.scheme
    code = nil
    scheme = request.url.scheme
    responseBody = request.body
    date = Date()
    isFinished = false
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
//    credentials = [:]
    var headers = request.allHTTPHeaderFields ?? [:]
    requestBody = request.httpBody
    isFinished = false

    session?.configuration.httpAdditionalHeaders?
      .filter {  $0.0 != AnyHashable("Cookie") }
      .forEach { element in
        guard let key = element.0 as? String, let value = element.1 as? String else { return }
        headers[key] = value
      }
    self.requestHeaders = headers

    // if the target server uses HTTP Basic Authentication, collect username and password
//    if let credentialStorage = session?.configuration.urlCredentialStorage,
//       let host = self.host,
//       let port = self.port {
//      let protectionSpace = URLProtectionSpace(
//        host: host,
//        port: port,
//        protocol: scheme,
//        realm: host,
//        authenticationMethod: NSURLAuthenticationMethodHTTPBasic
//      )
//
//      if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
//        for credential in credentials {
//          guard let user = credential.user, let password = credential.password else { continue }
//          self.credentials[user] = password
//        }
//      }
//    }

//    if let session = session, let url = request.url, session.configuration.httpShouldSetCookies {
//      if let cookieStorage = session.configuration.httpCookieStorage,
//         let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
//        self.cookies = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }
//      }
//    }
  }

  mutating func initResponse(response: URLResponse) {
    guard let response = response as? HTTPURLResponse else {return}
    code = response.statusCode
    responseHeaders = response.allHeaderFields.reduce(into: [String:String]()) { $0["\($1.key)"] = "\($1.value)" }
  }

  public func overview() -> [String: String] {
    var overview: [String: String] = [:]
    overview["URL"] = url
    if let method { overview["Method"] = method }
    if let code { overview["Response code"] = "\(code)" }
    if let error { overview["Error"] = String(describing: error) }
    if let errorClientDescription { overview["URLError Description"] = errorClientDescription.localizedDescription }
    return overview
  }
}

extension Data {
  var prettyPrintedJSONString: String? {
    guard
      let object = try? JSONSerialization.jsonObject(with: self, options: []),
      let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
    else { return nil }

    return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/")
  }

  var dict: [String: Any] {
    guard let object = try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any] else { return [:] }
    return object
  }
}
