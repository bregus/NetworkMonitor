import Foundation

public final class NetwrokListenerUrlProtocol: URLProtocol {
  struct Constants {
    static let RequestHandledKey = "NetworkListenerUrlProtocol"
  }

  var session: URLSession?
  var sessionTask: URLSessionDataTask?
  var currentRequest: RequestModel?

  override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
    super.init(request: request, cachedResponse: cachedResponse, client: client)

    if session == nil {
      session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
  }

  public override class func canInit(with request: URLRequest) -> Bool {
    if NetwrokListenerUrlProtocol.property(forKey: Constants.RequestHandledKey, in: request) != nil {
      return false
    }
    return true
  }

  public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  public override func startLoading() {
    guard let newRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest) else { return }
    NetwrokListenerUrlProtocol.setProperty(true, forKey: Constants.RequestHandledKey, in: newRequest)
    sessionTask = session?.dataTask(with: newRequest as URLRequest)
    sessionTask?.resume()

    currentRequest = RequestModel(request: newRequest, session: session)
    saveRequest()
  }

  public override func stopLoading() {
    sessionTask?.cancel()
    currentRequest?.requestBody = body(from: request)
    if let startDate = currentRequest?.date{
      currentRequest?.duration = fabs(startDate.timeIntervalSinceNow) * 1000
    }

    saveRequest()
    session?.invalidateAndCancel()
  }

  private func body(from request: URLRequest) -> Data? {
    request.httpBody ?? request.getHttpBodyStreamData()
  }

  private func saveRequest() {
    guard let request = currentRequest else { return }
    Storage.shared.saveRequest(request: request)
  }

  deinit {
    session = nil
    sessionTask = nil
    currentRequest = nil
  }
}

extension NetwrokListenerUrlProtocol: URLSessionDataDelegate {
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    client?.urlProtocol(self, didLoad: data)
    if currentRequest?.responseBody == nil{
      currentRequest?.responseBody = data
    }
    else{
      currentRequest?.responseBody?.append(data)
    }
  }

  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
    currentRequest?.updateWith(response: response)
    completionHandler(.allow)
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      currentRequest?.error = error
      saveRequest()
      client?.urlProtocol(self, didFailWithError: error)
    } else {
      client?.urlProtocolDidFinishLoading(self)
    }
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
    client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
    completionHandler(request)
  }

  public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    guard let error = error else { return }
    currentRequest?.error = error
    saveRequest()
    client?.urlProtocol(self, didFailWithError: error)
  }

  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let protectionSpace = challenge.protectionSpace
    let sender = challenge.sender

    if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
      if let serverTrust = protectionSpace.serverTrust {
        let credential = URLCredential(trust: serverTrust)
        sender?.use(credential, for: challenge)
        completionHandler(.useCredential, credential)
        return
      }
    }
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    currentRequest?.metrics = Metrics(metrics: metrics)
  }

  public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    client?.urlProtocolDidFinishLoading(self)
  }
}
