//
//  Data.swift
//  
//
//  Created by Рома Сумороков on 29.06.2023.
//

import Foundation

extension Int64 {
  var byteCount: String {
    if (self < 1000) { return "\(self) B" }
    let exp = Int(log2(Double(self)) / log2(1000.0))
    let unit = ["KB", "MB", "GB", "TB", "PB", "EB"][exp - 1]
    let number = Double(self) / pow(1000, Double(exp))
    if exp <= 1 || number >= 100 {
      return String(format: "%.0f %@", number, unit)
    } else {
      return String(format: "%.1f %@", number, unit).replacingOccurrences(of: ".0", with: "")
    }
  }
}

extension Data {
  var weight: String {
    Int64(count).byteCount
  }
}
