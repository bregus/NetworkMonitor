//
//  Date.swift
//  
//
//  Created by Рома Сумороков on 05.04.2023.
//

import Foundation

extension Date {
  func stringWithFormat(dateFormat: String, timezone: TimeZone? = nil) -> String? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    if let timezone {
      dateFormatter.timeZone = timezone
    }
    return dateFormatter.string(from: self)
  }
}
