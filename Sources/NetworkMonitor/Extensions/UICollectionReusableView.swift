//
//  UICollectionReusableView.swift
//  
//
//  Created by Рома Сумороков on 04.04.2023.
//

import UIKit

extension UITableViewCell {
  static var reuseIdentifier: String {
    return String(describing: Self.self)
  }
}
