//
//  Data.swift
//  
//
//  Created by Рома Сумороков on 29.06.2023.
//

import Foundation

extension Data {
  var weight: String {
    return ByteCountFormatter().string(fromByteCount: Int64(self.count))
  }
}
