//
//  UIImage.swift
//
//
//  Created by Roman Sumorokov on 01.11.2023.
//

import UIKit

extension UIImage {
  func resize(to size: CGSize) -> UIImage {
    UIGraphicsImageRenderer(size: size).image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }
}
