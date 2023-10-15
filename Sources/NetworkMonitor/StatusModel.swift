//
//  StatusCodeFormatter.swift
//  
//
//  Created by Рома Сумороков on 04.09.2023.
//

import Foundation
import UIKit

struct StatusModel {
  let systemImage: String
  let tint: UIColor
  let title: String

  init(request: RequestModel) {
    switch request.state {
    case .pending:
      self.systemImage = "clock.fill"
      self.tint = .systemOrange
      self.title = "IN PROGRESS"
    case .success:
      self.systemImage = "checkmark.circle.fill"
      self.tint = .systemGreen
      self.title = StatusCodeFormatter.string(for: request.code)
    case .failure:
      self.systemImage = "exclamationmark.circle.fill"
      self.tint = .systemRed
      self.title = ErrorFormatter.shortErrorDescription(for: request)
    }
  }
}

enum StatusCodeFormatter {
  static func string(for statusCode: Int32) -> String {
    string(for: Int(statusCode))
  }

  static func string(for statusCode: Int) -> String {
    switch statusCode {
    case 0: return "Success"
    case 200: return "200 OK"
    case 418: return "418 Teapot"
    case 429: return "429 Too many requests"
    case 451: return "451 Unavailable for Legal Reasons"
    default: return "\(statusCode) \( HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized)"
    }
  }
}

enum ErrorFormatter {
  static func shortErrorDescription(for request: RequestModel) -> String {
    if let errorCode = (request.error as? URLError)?.errorCode {
      return descriptionForURLErrorCode(errorCode)
    } else {
      return StatusCodeFormatter.string(for: request.code)
    }
  }

  static func descriptionForURLErrorCode(_ code: Int) -> String {
    switch code {
    case NSURLErrorUnknown: return "Unknown"
    case NSURLErrorCancelled: return "Cancelled"
    case NSURLErrorBadURL: return "Bad URL"
    case NSURLErrorTimedOut: return "Timed Out"
    case NSURLErrorUnsupportedURL: return "Unsupported URL"
    case NSURLErrorCannotFindHost: return "Cannot Find Host"
    case NSURLErrorCannotConnectToHost: return "Cannot Connect To Host"
    case NSURLErrorNetworkConnectionLost: return "Network Connection Lost"
    case NSURLErrorDNSLookupFailed: return "DNS Lookup Failed"
    case NSURLErrorHTTPTooManyRedirects: return "HTTP Too Many Redirects"
    case NSURLErrorResourceUnavailable: return "Resource Unavailable"
    case NSURLErrorNotConnectedToInternet: return "Not Connected To Internet"
    case NSURLErrorRedirectToNonExistentLocation: return "Redirect To Non Existent Location"
    case NSURLErrorBadServerResponse: return "Bad Server Response"
    case NSURLErrorUserCancelledAuthentication: return "User Cancelled Authentication"
    case NSURLErrorUserAuthenticationRequired: return "User Authentication Required"
    case NSURLErrorZeroByteResource: return "Zero Byte Resource"
    case NSURLErrorCannotDecodeRawData: return "Cannot Decode Raw Data"
    case NSURLErrorCannotDecodeContentData: return "Cannot Decode Content Data"
    case NSURLErrorCannotParseResponse: return "Cannot Parse Response"
    case NSURLErrorAppTransportSecurityRequiresSecureConnection: return "ATS Requirement Failed"
    case NSURLErrorFileDoesNotExist: return "File Does Not Exist"
    case NSURLErrorFileIsDirectory: return "File Is Directory"
    case NSURLErrorNoPermissionsToReadFile: return "No Permissions To Read File"
    case NSURLErrorDataLengthExceedsMaximum: return "Data Length Exceeds Maximum"
    case NSURLErrorFileOutsideSafeArea: return "File Outside Safe Area"
    case NSURLErrorSecureConnectionFailed: return "Secure Connection Failed"
    case NSURLErrorServerCertificateHasBadDate: return "Server Certificate Bad Date"
    case NSURLErrorServerCertificateUntrusted: return "Server Certificate Untrusted"
    case NSURLErrorServerCertificateHasUnknownRoot: return "Server Certificate Unknown Root"
    case NSURLErrorServerCertificateNotYetValid: return "Server Certificate Not Valid"
    case NSURLErrorClientCertificateRejected: return "Client Certificate Rejected"
    case NSURLErrorClientCertificateRequired: return "Client Certificate Required"
    case NSURLErrorCannotLoadFromNetwork: return "Cannot Load From Network"
    case NSURLErrorCannotCreateFile: return "Cannot Create File"
    case NSURLErrorCannotOpenFile: return "Cannot Open File"
    case NSURLErrorCannotCloseFile: return "Cannot Close File"
    case NSURLErrorCannotWriteToFile: return "Cannot Write To File"
    case NSURLErrorCannotRemoveFile: return "Cannot Remove File"
    case NSURLErrorCannotMoveFile: return "Cannot Move File"
    case NSURLErrorDownloadDecodingFailedMidStream: return "Download Decoding Failed"
    case NSURLErrorDownloadDecodingFailedToComplete: return "Download Decoding Failed"
    case NSURLErrorInternationalRoamingOff: return "Roaming Off"
    case NSURLErrorCallIsActive: return "Call Is Active"
    case NSURLErrorDataNotAllowed: return "Data Not Allowed"
    case NSURLErrorRequestBodyStreamExhausted: return "Request Stream Exhausted"
    case NSURLErrorBackgroundSessionRequiresSharedContainer: return "Background Session Requires Shared Container"
    case NSURLErrorBackgroundSessionInUseByAnotherProcess: return "Background Session In Use By Another Process"
    case NSURLErrorBackgroundSessionWasDisconnected: return "Background Session Disconnected"
    default: return "–"
    }
  }
}
