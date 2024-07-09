import UIKit

let kJSONFont = UIFont.boldSystemFont(ofSize: 14)

let kJSONKeyColor = UIColor.label
let kJSONSymbolColor = UIColor.label

let kJSONNullValueColor = UIColor(rgb: 0xFF7AB2)
let kJSONBoolValueColor = UIColor(rgb: 0xFF7AB2)
var kJSONNumberValueColor: UIColor {
  UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(rgb: 0xD9C97C) : UIColor(rgb: 0xAD3DA4)
}
let kJSONStringValueColor = UIColor(rgb: 0xff8170)

extension NSAttributedString {
  convenience init(string: String, font: UIFont = kJSONFont, color: UIColor, style: NSParagraphStyle? = nil) {
    var attributes = [NSAttributedString.Key.font: font,
                      NSAttributedString.Key.foregroundColor: color]
    if let style = style {
      attributes[NSAttributedString.Key.paragraphStyle] = style
    }
    self.init(string: string, attributes: attributes)
  }
}

extension NSAttributedString {
  static func render(_ element: Any?) -> NSAttributedString {
    return render(element: element, level: 0, ext: 0)
  }

  private static func render(element: Any?, level: Int, ext: CGFloat, style: NSParagraphStyle? = nil) -> NSAttributedString {
    guard let element = element, element is NSNull == false else {
      return NSAttributedString.init(string: "null", color: kJSONNullValueColor)
    }

    switch element {
    case let data as Data:
      return attributedString(data: data)
    case let tupleArray as [(String, String)]:
      return attributedString(items: tupleArray)
    case let dic as [String: Any]:
      return attributedString(dic: dic, level: level, ext: ext)
    case let arr as [Any]:
      return attributedString(arr: arr, level: level, ext: ext)
    case let number as NSNumber:
      if number.isBool {
        return .init(string: number.boolValue ? "true" : "false", color: kJSONBoolValueColor)
      }
      var string = "\(number)"
      if number.objCType.pointee == 100 {
        string = (Decimal.init(string: String.init(format: "%f", number.doubleValue))! as NSDecimalNumber).stringValue
      }
      return .init(string: string, color: kJSONNumberValueColor, style: style)
    case let string as String:
      return .init(string: "\"" + string + "\"", color: kJSONStringValueColor, style: style)
    default:
      return .init(string: "\(element)", color: kJSONStringValueColor, style: style)
    }
  }

  private static func attributedString(dic: [String: Any], level: Int, ext: CGFloat) -> NSMutableAttributedString {
    let headPara = NSMutableParagraphStyle()
    headPara.firstLineHeadIndent = CGFloat(level * 10)

    let mattr = NSMutableAttributedString.init(string: "{", color: kJSONSymbolColor, style: headPara)

    if (dic.isEmpty == false) {
      mattr.append(NSAttributedString.init(string: "\n"))
    }

    for (idx, element) in dic.enumerated() {

      let key = "\"" + element.key + "\""
//      let key = element.key
      let width = (key as NSString).boundingRect(with: CGSize.init(width: CGFloat.infinity, height: kJSONFont.lineHeight), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: kJSONFont], context: nil).size.width + 10

      let para = NSMutableParagraphStyle()
      para.firstLineHeadIndent = CGFloat((level + 1) * 10)
//      para.headIndent = CGFloat(level * 10) + width + ext + 5
      para.lineBreakMode = .byCharWrapping

      mattr.append(NSAttributedString.init(string: key, color: kJSONKeyColor, style: para))

      mattr.append(NSAttributedString.init(string: ": ", color: kJSONSymbolColor))

      mattr.append(.render(element: element.value, level: level + 1, ext: width + ext))

      if idx != dic.count - 1 {
        mattr.append(NSAttributedString.init(string: ",", color: kJSONSymbolColor))
      }
      mattr.append(NSAttributedString.init(string: "\n"))
    }

    let tailPara = NSMutableParagraphStyle()
    tailPara.firstLineHeadIndent = CGFloat(level * 10)

    mattr.append(NSAttributedString.init(string: "}", color: kJSONSymbolColor, style: tailPara))

    return mattr
  }

  private static func attributedString(arr: [Any], level: Int, ext: CGFloat) -> NSMutableAttributedString {

    let headPara = NSMutableParagraphStyle()
    headPara.firstLineHeadIndent = CGFloat(level * 10)

    let mattr = NSMutableAttributedString.init(string: "[", color: kJSONSymbolColor, style: headPara)

    if (arr.isEmpty == false) {
      mattr.append(NSAttributedString.init(string: "\n"))
    }

    for (idx, element) in arr.enumerated() {

      let index = String(idx)

      let width = (index as NSString).boundingRect(with: CGSize.init(width: CGFloat.infinity, height: kJSONFont.lineHeight), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: kJSONFont], context: nil).size.width + 10

      let para = NSMutableParagraphStyle()
      para.firstLineHeadIndent = CGFloat(level * 10) + 10
      para.lineBreakMode = .byCharWrapping

      mattr.append(.render(element: element, level: level + 1, ext: width + ext, style: para))

      if idx != arr.count - 1 {
        mattr.append(NSAttributedString.init(string: ",", color: kJSONSymbolColor))
      }
      mattr.append(NSAttributedString.init(string: "\n"))
    }

    let tailPara = NSMutableParagraphStyle()
    tailPara.firstLineHeadIndent = CGFloat(level * 10)

    mattr.append(NSAttributedString.init(string: "]", color: kJSONSymbolColor, style: tailPara))

    return mattr
  }

  private static func attributedString(items: [(String, String)]) -> NSMutableAttributedString {
    let result = NSMutableAttributedString()
    return items.reduce(into: result) { partialResult, elem in
      partialResult.append("\(elem.0): ".key())
      partialResult.append("\(elem.1)\n".value())
    }
  }

  private static func attributedString(data: Data) -> NSAttributedString {
    let json = try? JSONDecoder().decode(JSON.self, from: data)
    return .render(json?.value)
  }
}

private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

extension NSNumber {
  fileprivate var isBool: Bool {
    let objCType = String(cString: self.objCType)
    if (self.compare(trueNumber) == .orderedSame && objCType == trueObjCType) || (self.compare(falseNumber) == .orderedSame && objCType == falseObjCType) {
      return true
    } else {
      return false
    }
  }
}

extension String {
  func header() -> NSAttributedString {
    let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.secondaryLabel]
    return NSAttributedString(string: self, attributes: attrs)
  }

  func key() -> NSAttributedString {
    let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: kJSONStringValueColor]
    return NSAttributedString(string: self, attributes: attrs)
  }

  func value() -> NSAttributedString {
    let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.label]
    return NSAttributedString(string: self, attributes: attrs)
  }
}

struct JSON: Decodable {
  var value: Any?

  public init(from decoder: Decoder) throws {
    if let container = try? decoder.container(keyedBy: JSONCodingKeys.self) {
      self.value = decode(fromObject: container)
    } else if var array = try? decoder.unkeyedContainer() {
      self.value = decode(fromArray: &array)
    } else if let value = try? decoder.singleValueContainer() {
      if value.decodeNil() {
        self.value = nil
      } else {
        if let result = try? value.decode(Int.self) { self.value = result }
        if let result = try? value.decode(Double.self) { self.value = result }
        if let result = try? value.decode(String.self) { self.value = result }
        if let result = try? value.decode(Bool.self) { self.value = result }
      }
    }
  }

  func decode(fromArray container: inout UnkeyedDecodingContainer) -> [Any] {
    var result: [Any] = []

    while !container.isAtEnd {
      if let value = try? container.decode(String.self) { result.append(value) }
      else if let value = try? container.decode(Int.self) { result.append(value) }
      else if let value = try? container.decode(Double.self) { result.append(value) }
      else if let value = try? container.decode(Bool.self) { result.append(value) }
      else if let nestedContainer = try? container.nestedContainer(keyedBy: JSONCodingKeys.self) {
        result.append(decode(fromObject: nestedContainer))
      }
      else if var nestedArray = try? container.nestedUnkeyedContainer() {
        result.append(decode(fromArray: &nestedArray))
      } else if (try? container.decodeNil()) == true {
        result.append(Optional<Any>(nil) as Any)
      }
    }

    return result
  }

  func decode(fromObject container: KeyedDecodingContainer<JSONCodingKeys>) -> [String: Any] {
    var result: [String: Any] = [:]

    for key in container.allKeys {
      if let val = try? container.decode(Int.self, forKey: key) { result[key.stringValue] = val }
      else if let val = try? container.decode(Double.self, forKey: key) { result[key.stringValue] = val }
      else if let val = try? container.decode(String.self, forKey: key) { result[key.stringValue] = val }
      else if let val = try? container.decode(Bool.self, forKey: key) { result[key.stringValue] = val }
      else if let nestedContainer = try? container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key) {
        result[key.stringValue] = decode(fromObject: nestedContainer)
      } else if (try? container.decodeNil(forKey: key)) == true  {
        result.updateValue(Optional<Any>(nil) as Any, forKey: key.stringValue)
      } else if var nestedArray = try? container.nestedUnkeyedContainer(forKey: key) {
        result[key.stringValue] = decode(fromArray: &nestedArray)
      }
    }

    return result
  }
}

struct JSONCodingKeys: CodingKey {
  var stringValue: String

  init(stringValue: String) {
    self.stringValue = stringValue
  }

  var intValue: Int?

  init?(intValue: Int) {
    self.init(stringValue: "\(intValue)")
    self.intValue = intValue
  }
}
