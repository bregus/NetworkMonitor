import Foundation

struct ContentType: Hashable, ExpressibleByStringLiteral {
  var type: String
  var parameters: [String: String]
  var rawValue: String

  init?(rawValue: String) {
    let parts = rawValue.split(separator: ";")
    guard let type = parts.first else { return nil }
    self.type = type.lowercased()
    var parameters: [String: String] = [:]
    for (key, value) in parts.dropFirst().compactMap(parseParameter) {
      parameters[key] = value
    }
    self.parameters = parameters
    self.rawValue = rawValue
  }

  static let any = ContentType(rawValue: "*/*")!

  init(stringLiteral value: String) {
    self = ContentType(rawValue: value) ?? .any
  }

  var isJSON: Bool { type.contains("json") }
  var isPDF: Bool { type.contains("pdf") }
  var isImage: Bool { type.hasPrefix("image/") }
  var isHTML: Bool { type.contains("html") }
  var isEncodedForm: Bool { type == "application/x-www-form-urlencoded" }
}

private func parseParameter(_ param: Substring) -> (String, String)? {
  let parts = param.split(separator: "=")
  guard parts.count == 2, let name = parts.first, let value = parts.last else {
    return nil
  }
  return (name.trimmingCharacters(in: .whitespaces), value.trimmingCharacters(in: .whitespaces))
}
