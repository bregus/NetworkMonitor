import UIKit

final class MenuBuilder {
  private let title: String
  private let image: String
  private var actions: [UIMenuElement] = []

  init(title: String = "", image: String = "") {
    self.title = title
    self.image = image
  }

  func append(title: String, imageName: String = "", isOn: Bool = false, attributes: UIMenuElement.Attributes = [], action: @escaping (UIAction) -> Void) -> Self {
    let action = UIAction(title: title, image: imageName.isEmpty ? nil : UIImage(systemName: imageName), attributes: attributes, handler: action)
    action.state = isOn ? .on : .off
    actions.append(action)
    return self
  }

  func append(menu: UIMenu) -> Self {
    actions.append(menu)
    return self
  }

  func build() -> UIMenu {
    return UIMenu(title: title, image: UIImage(systemName: image), children: actions)
  }

  static func exportMenu(for request: RequestModel) -> UIMenu {
    MenuBuilder(title: "Export")
      .export(title: "Text", export: RequestExporter.txtExport(request: request))
      .export(title: "Curl", export: RequestExporter.curlExport(request: request))
      .build()
  }

  private func openShareSheet(item: Any?) {
    guard let item else { return }
    let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
    UIViewController.currentViewController()?.present(activity, animated: true)
  }

  private func export(title: String, export: Any?) -> Self {
    actions.append(UIAction(title: title) { _ in self.openShareSheet(item: export) })
    return self
  }
}
