import Foundation

struct ContentType: Hashable {
  var type: String
  var rawValue: String

  init?(rawValue: String) {
    let parts = rawValue.split(separator: ";")
    guard let type = parts.first else { return nil }
    self.type = type.lowercased()
    self.rawValue = rawValue
  }

  var isJSON: Bool { type.contains("json") }
  var isPDF: Bool { type.contains("pdf") }
  var isImage: Bool { type.hasPrefix("image/") }
  var isHTML: Bool { type.contains("html") }
  var isEncodedForm: Bool { type == "application/x-www-form-urlencoded" }
}
