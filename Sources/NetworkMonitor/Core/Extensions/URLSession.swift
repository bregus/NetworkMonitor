//
//  URLSession.swift
//  
//
//  Created by Roma Sumorokov on 17.07.2024.
//

import Foundation

extension URLSession {
  @objc class func monitor_init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) -> URLSession {
    guard !String(describing: delegate).contains("GTMSessionFetcher") else {
      return self.monitor_init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
    configuration.protocolClasses = [NetwrokListenerUrlProtocol.self] + (configuration.protocolClasses ?? [])
    return self.monitor_init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
  }

  static func enableAutomaticRegistration() {
    if let lhs = class_getClassMethod(URLSession.self, #selector(URLSession.init(configuration:delegate:delegateQueue:))),
       let rhs = class_getClassMethod(URLSession.self, #selector(URLSession.monitor_init(configuration:delegate:delegateQueue:))) {
      method_exchangeImplementations(lhs, rhs)
    }
  }

  static func disableAutomaticRegistration() {
    if let lhs = class_getClassMethod(URLSession.self, #selector(URLSession.monitor_init(configuration:delegate:delegateQueue:))),
       let rhs = class_getClassMethod(URLSession.self, #selector(URLSession.init(configuration:delegate:delegateQueue:))) {
      method_exchangeImplementations(lhs, rhs)
    }
  }
}
