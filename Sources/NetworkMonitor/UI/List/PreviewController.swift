//
//  PreviewController.swift
//  
//
//  Created by Рома Сумороков on 01.11.2023.
//

import UIKit

final class PreviewController: UIViewController {
  private let textView: UITextView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupTextView()
  }

  func setText(_ text: NSAttributedString) {
    textView.attributedText = text
    textView.sizeToFit()
    preferredContentSize = textView.contentSize
  }

  private func setupTextView() {
    textView.dataDetectorTypes = .link
    textView.isEditable = false
    textView.isScrollEnabled = false
  }

  override func loadView() {
    self.view = textView
  }
}
