import UIKit

final class MenuBuilder {
  private let title: String
  private var actions: [UIAction] = []

  init(title: String = "") {
    self.title = title
  }

  func export(title: String, export: Any?) -> Self {
    actions.append(UIAction(title: title) { _ in self.openShareSheet(item: export) })
    return self
  }

  func append(title: String, imageName: String = "", attributes: UIMenuElement.Attributes = [], action: @escaping (UIAction) -> Void) -> Self {
    actions.append(UIAction(title: title, image: imageName.isEmpty ? nil : UIImage(systemName: imageName), attributes: attributes, handler: action))
    return self
  }

  func build() -> UIMenu {
    return UIMenu(title: title, children: actions)
  }

  private func openShareSheet(item: Any?) {
    guard let item else { return }
    let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
    UIViewController.currentViewController()?.present(activity, animated: true)
  }
}
