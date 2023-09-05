//
//  UILabel.swift
//  
//
//  Created by Рома Сумороков on 29.06.2023.
//

import UIKit

extension UILabel {
  func setIconAndText(icon: String, text: String) {
    let imageAttachment = NSTextAttachment()
    imageAttachment.image = UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate)
    let imageOffsetY: CGFloat = -2.0
    imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: font.pointSize, height: font.pointSize)
    let attachmentString = NSAttributedString(attachment: imageAttachment)
    let completeText = NSMutableAttributedString(string: "")
    completeText.append(attachmentString)
    let textAfterIcon = NSAttributedString(string: text)
    completeText.append(textAfterIcon)
    textAlignment = .center
    attributedText = completeText
  }
}
