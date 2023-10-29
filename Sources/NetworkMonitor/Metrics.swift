import Foundation

struct Metrics {
  var taskInterval: DateInterval
  var redirectCount: Int
  var transactions: [TransactionMetrics]
  var totalTransferSize: TransferSizeInfo { TransferSizeInfo(metrics: self) }

  init(metrics: URLSessionTaskMetrics) {
    self.taskInterval = metrics.taskInterval
    self.redirectCount = metrics.redirectCount
    self.transactions = metrics.transactionMetrics.map(TransactionMetrics.init)
  }
}

struct TransferSizeInfo {
  // MARK: Sent
  var totalBytesSent: Int64 { requestBodyBytesSent + requestHeaderBytesSent }
  var requestHeaderBytesSent: Int64 = 0
  var requestBodyBytesBeforeEncoding: Int64 = 0
  var requestBodyBytesSent: Int64 = 0

  // MARK: Received
  var totalBytesReceived: Int64 { responseBodyBytesReceived + responseHeaderBytesReceived }
  var responseHeaderBytesReceived: Int64 = 0
  var responseBodyBytesAfterDecoding: Int64 = 0
  var responseBodyBytesReceived: Int64 = 0

  var totalBytes: String {
    "Send: \(totalBytesSent.byteCount)\nReceived: \(totalBytesReceived.byteCount)"
  }

  init() {}

  init(metrics: Metrics) {
    var size = TransferSizeInfo()
    for transaction in metrics.transactions {
      size = size.merging(transaction.transferSize)
    }
    self = size
  }

  init(metrics: URLSessionTaskTransactionMetrics) {
    requestHeaderBytesSent = metrics.countOfRequestHeaderBytesSent
    requestBodyBytesBeforeEncoding = metrics.countOfRequestBodyBytesBeforeEncoding
    requestBodyBytesSent = metrics.countOfRequestBodyBytesSent
    responseHeaderBytesReceived = metrics.countOfResponseHeaderBytesReceived
    responseBodyBytesReceived = metrics.countOfResponseBodyBytesReceived
    responseBodyBytesAfterDecoding = metrics.countOfResponseBodyBytesAfterDecoding
  }

  func merging(_ size: TransferSizeInfo) -> TransferSizeInfo {
    var size = size
    // Using overflow operators just in case
    size.requestHeaderBytesSent &+= requestHeaderBytesSent
    size.requestBodyBytesBeforeEncoding &+= requestBodyBytesBeforeEncoding
    size.requestBodyBytesSent &+= requestBodyBytesSent
    size.responseHeaderBytesReceived &+= responseHeaderBytesReceived
    size.responseBodyBytesAfterDecoding &+= responseBodyBytesAfterDecoding
    size.responseBodyBytesReceived &+= responseBodyBytesReceived
    return size
  }
}

struct TransactionMetrics {
  var fetchType: URLSessionTaskMetrics.ResourceFetchType {
    type.flatMap(URLSessionTaskMetrics.ResourceFetchType.init) ?? .networkLoad
  }

  var request: RequestModel
  var timing: TransactionTimingInfo
  var networkProtocol: String?
  var transferSize: TransferSizeInfo
  var conditions: Conditions
  var localAddress: String?
  var remoteAddress: String?
  var localPort: Int?
  var remotePort: Int?
  var negotiatedTLSProtocolVersion: tls_protocol_version_t? {
    tlsVersion.flatMap(tls_protocol_version_t.init)
  }
  var negotiatedTLSCipherSuite: tls_ciphersuite_t? {
    tlsSuite.flatMap(tls_ciphersuite_t.init)
  }

  private var tlsVersion: UInt16?
  private var tlsSuite: UInt16?
  private var type: Int?

  init(metrics: URLSessionTaskTransactionMetrics) {
    self.request = RequestModel(request: metrics.request as NSURLRequest, session: nil)
    request.updateWith(response: metrics.response)
    self.timing = TransactionTimingInfo(metrics: metrics)
    self.networkProtocol = metrics.networkProtocolName
    self.type = (metrics.resourceFetchType == .networkLoad ? nil :  metrics.resourceFetchType.rawValue)
    self.transferSize = TransferSizeInfo(metrics: metrics)
    self.conditions = Conditions(metrics: metrics)
    self.localAddress = metrics.localAddress
    self.remoteAddress = metrics.remoteAddress
    self.localPort = metrics.localPort
    self.remotePort = metrics.remotePort
    self.tlsVersion = metrics.negotiatedTLSProtocolVersion?.rawValue
    self.tlsSuite = metrics.negotiatedTLSCipherSuite?.rawValue
  }

  struct Conditions {
    let isProxyConnection: Bool
    let isReusedConnection: Bool
    let isCellular: Bool
    let isExpensive: Bool
    let isConstrained: Bool
    let isMultipath: Bool

    init(metrics: URLSessionTaskTransactionMetrics) {
      isProxyConnection = metrics.isProxyConnection
      isReusedConnection = metrics.isReusedConnection
      isCellular = metrics.isCellular
      isExpensive = metrics.isExpensive
      isConstrained = metrics.isConstrained
      isMultipath = metrics.isMultipath
    }
  }
}

struct TransactionTimingInfo {
  var fetchStartDate: Date?
  var domainLookupStartDate: Date?
  var domainLookupEndDate: Date?
  var connectStartDate: Date?
  var secureConnectionStartDate: Date?
  var secureConnectionEndDate: Date?
  var connectEndDate: Date?
  var requestStartDate: Date?
  var requestEndDate: Date?
  var responseStartDate: Date?
  var responseEndDate: Date?

  var duration: TimeInterval? {
    guard let startDate = fetchStartDate, let endDate = responseEndDate else {
      return nil
    }
    return max(0, endDate.timeIntervalSince(startDate))
  }

  init(metrics: URLSessionTaskTransactionMetrics) {
    self.fetchStartDate = metrics.fetchStartDate
    self.domainLookupStartDate = metrics.domainLookupStartDate
    self.domainLookupEndDate = metrics.domainLookupEndDate
    self.connectStartDate = metrics.connectStartDate
    self.secureConnectionStartDate = metrics.secureConnectionStartDate
    self.secureConnectionEndDate = metrics.secureConnectionEndDate
    self.connectEndDate = metrics.connectEndDate
    self.requestStartDate = metrics.requestStartDate
    self.requestEndDate = metrics.requestEndDate
    self.responseStartDate = metrics.responseStartDate
    self.responseEndDate = metrics.responseEndDate
  }

  init() {}
}
