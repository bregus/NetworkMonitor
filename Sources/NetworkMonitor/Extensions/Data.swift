//
//  Data.swift
//  
//
//  Created by Рома Сумороков on 29.06.2023.
//

import Foundation

extension Data {
  var weight: String {
    let bytes = Int64(count)
    if (bytes < 1000) { return "\(bytes) B" }
    let exp = Int(log2(Double(bytes)) / log2(1000.0))
    let unit = ["KB", "MB", "GB", "TB", "PB", "EB"][exp - 1]
    let number = Double(bytes) / pow(1000, Double(exp))
    if exp <= 1 || number >= 100 {
      return String(format: "%.0f %@", number, unit)
    } else {
      return String(format: "%.1f %@", number, unit).replacingOccurrences(of: ".0", with: "")
    }
  }

  var prettyPrintedJSONString: String? {
    guard
      let object = try? JSONSerialization.jsonObject(with: self, options: []),
      let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
    else { return String(data: self, encoding: .utf8) ?? String(data: self, encoding: .ascii) }

    return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/")
  }

  var dict: [String: Any] {
    guard let object = try? JSONSerialization.jsonObject(with: self, options: []) as? [String: Any] else { return [:] }
    return object
  }
}
