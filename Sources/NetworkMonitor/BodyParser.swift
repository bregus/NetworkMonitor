import UIKit

let kJSONFont = UIFont.boldSystemFont(ofSize: 14)

let kJSONKeyColor = UIColor(rgb: 0xff8170)
let kJSONIndexColor = UIColor(rgb: 0x4FB0CB)
let kJSONSymbolColor = UIColor.black

let kJSONNullValueColor = UIColor(rgb: 0xFF7AB2)
let kJSONBoolValueColor = UIColor(rgb: 0xFF7AB2)
let kJSONNumberValueColor = UIColor(rgb: 0xD9C97C)
let kJSONStringValueColor = UIColor(rgb: 0xff8170)

extension NSAttributedString {
  convenience init(string: String, font: UIFont = kJSONFont, color: UIColor , style: NSParagraphStyle? = nil) {
    var attributes = [NSAttributedString.Key.font: font,
                      NSAttributedString.Key.foregroundColor: color]
    if let style = style {
      attributes[NSAttributedString.Key.paragraphStyle] = style
    }
    self.init(string: string, attributes: attributes)
  }
}

extension NSAttributedString {
  @objc class public func render(_ element: Any?) -> NSAttributedString {
    return render(element: element, level: 0, ext: 0)
  }

  private class func render(element: Any?, level: Int, ext: CGFloat) -> NSAttributedString {
    guard let element = element, element is NSNull == false else {
      return NSAttributedString.init(string: "null", color: kJSONNullValueColor)
    }

    switch element {
    case let dic as [String: Any]:
      return attributedString(dic: dic, level: level, ext: ext)
    case let arr as [Any]:
      return attributedString(arr: arr, level: level, ext: ext)
    case let number as NSNumber:
      if number.isBool {
        return NSAttributedString.init(string: number.boolValue ? "true":"false", color: kJSONBoolValueColor)
      }
      var string = "\(number)"
      if number.objCType.pointee == 100 {
        string = (Decimal.init(string: String.init(format: "%f", number.doubleValue))! as NSDecimalNumber).stringValue
      }
      return NSAttributedString.init(string: string, color: kJSONNumberValueColor)
    case let string as String:
      return NSAttributedString.init(string: "\"" + string + "\"", color: kJSONStringValueColor)
    default:
      return NSAttributedString.init(string: "\(element)", color: kJSONStringValueColor)
    }
  }

  private class func attributedString(dic: [String: Any], level: Int, ext: CGFloat) -> NSMutableAttributedString {

    let headPara = NSMutableParagraphStyle()
    headPara.firstLineHeadIndent = CGFloat(level * 10)

    let mattr = NSMutableAttributedString.init(string: "{", color: kJSONSymbolColor, style: headPara)

    if (dic.isEmpty == false) {
      mattr.append(NSAttributedString.init(string: "\n"))
    }

    for (idx, element) in dic.enumerated() {

      let key = "\"" + element.key + "\""

      let width = (key as NSString).boundingRect(with: CGSize.init(width: CGFloat.infinity, height: kJSONFont.lineHeight), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: kJSONFont], context: nil).size.width + 10

      let para = NSMutableParagraphStyle()
      para.firstLineHeadIndent = CGFloat((level + 1) * 10) + ext
      para.headIndent = CGFloat(level * 10) + width + ext + 5
      para.lineBreakMode = .byCharWrapping

      mattr.append(NSAttributedString.init(string: key, color: kJSONKeyColor, style: para))

      mattr.append(NSAttributedString.init(string: ":", color: kJSONSymbolColor))

      mattr.append(.render(element: element.value, level: level + 1, ext: width + ext))

      if idx != dic.count - 1 {
        mattr.append(NSAttributedString.init(string: ",", color: kJSONSymbolColor))
      }
      mattr.append(NSAttributedString.init(string: "\n"))
    }

    let tailPara = NSMutableParagraphStyle()
    tailPara.firstLineHeadIndent = CGFloat(level * 10) + ext

    mattr.append(NSAttributedString.init(string: "}", color: kJSONSymbolColor, style: tailPara))

    return mattr
  }

  private class func attributedString(arr: [Any], level: Int, ext: CGFloat) -> NSMutableAttributedString {

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
      para.firstLineHeadIndent = CGFloat(level * 10) + ext + 5
      para.headIndent = CGFloat(level * 10) + width + ext + 5
      para.lineBreakMode = .byCharWrapping

      mattr.append(NSAttributedString.init(string: index, color: kJSONIndexColor, style: para))

      mattr.append(NSAttributedString.init(string: ":", color: kJSONSymbolColor))

      mattr.append(.render(element: element, level: level + 1, ext: width + ext))

      if idx != arr.count - 1 {
        mattr.append(NSAttributedString.init(string: ",", color: kJSONSymbolColor))
      }
      mattr.append(NSAttributedString.init(string: "\n"))
    }

    let tailPara = NSMutableParagraphStyle()
    tailPara.firstLineHeadIndent = CGFloat(level * 10) + ext

    mattr.append(NSAttributedString.init(string: "]", color: kJSONSymbolColor, style: tailPara))

    return mattr
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

extension NSMutableAttributedString {
  public func append(_ element: Any?) {
    return append(.render(element))
  }
}
