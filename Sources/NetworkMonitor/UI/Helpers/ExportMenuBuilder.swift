import UIKit

final class ExportMenuBuilder {
  private var actions: [UIAction] = []

  @discardableResult
  func append(title: String, export: Any?) -> Self {
    actions.append(UIAction(title: title) { _ in self.openShareSheet(item: export) })
    return self
  }

  func build() -> UIMenu {
    return UIMenu(title: "Export", image: UIImage(systemName: "square.and.arrow.up"), children: actions)
  }

  private func openShareSheet(item: Any?) {
    guard let item else { return }
    let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
    UIViewController.currentViewController()?.present(activity, animated: true)
  }
}
