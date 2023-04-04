import Foundation

public struct RequestRepresentable {
  let id: String
  let url: String
  let host: String?
  let port: Int?
  let pathComponents: String?
  let scheme: String?
  let method: String?
  var code: Int? = nil
  public var headers: [String: String]
  public var responseHeaders: [String: String] = [:]
  public var httpBody: Data?
  var error: Error? = nil
  var duration: Double?
  let date: Date
  public var responseBody: Data? = nil
  public var errorClientDescription: Error? = nil
  var isFinished: Bool

  public init(request: URLRequest?, response: HTTPURLResponse?, error: Error?, data: Data?) {
    id = UUID().uuidString
    url = request?.url?.absoluteString ?? ""
    host = request?.url?.host
    port = request?.url?.port
    pathComponents = request?.url?.pathComponents.joined(separator: "/")
    scheme = request?.url?.scheme
    method = request?.httpMethod
    date = Date()
    headers = request?.allHTTPHeaderFields ?? [:]
    httpBody = request?.httpBody//?.prettyPrintedJSONString
    code = response?.statusCode
    self.error = error
    responseHeaders = response?.allHeaderFields.reduce(into: [String:String]()) { $0["\($1.key)"] = "\($1.value)" } ?? [:]
    responseBody = data//?.prettyPrintedJSONString
    isFinished = true
  }

  init(request: NSURLRequest, session: URLSession?) {
    id = UUID().uuidString
    url = request.url?.absoluteString ?? ""
    host = request.url?.host
    port = request.url?.port
    pathComponents = request.url?.pathComponents.joined()
    scheme = request.url?.scheme
    date = Date()
    method = request.httpMethod ?? "GET"
//    credentials = [:]
    var headers = request.allHTTPHeaderFields ?? [:]
    httpBody = request.httpBody
    isFinished = false


    // collect all HTTP Request headers except the "Cookie" header. Many request representations treat cookies with special parameters or structures. For cookie collection, refer to the bottom part of this method
    session?.configuration.httpAdditionalHeaders?
      .filter {  $0.0 != AnyHashable("Cookie") }
      .forEach { element in
        guard let key = element.0 as? String, let value = element.1 as? String else { return }
        headers[key] = value
      }
    self.headers = headers

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
    if let errorClientDescription { overview["URLError Description"] = String(describing: errorClientDescription) }
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
}
