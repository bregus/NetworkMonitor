import UIKit

final class ExportMenuBuilder {
  private let title: String
  private var actions: [UIAction] = []

  init(title: String = "") {
    self.title = title
  }

  func export(title: String, export: Any?) -> Self {
    actions.append(UIAction(title: title) { _ in self.openShareSheet(item: export) })
    return self
  }

  func append(title: String, action: @escaping (UIAction) -> Void) -> Self {
    actions.append(UIAction(title: title, handler: action))
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
