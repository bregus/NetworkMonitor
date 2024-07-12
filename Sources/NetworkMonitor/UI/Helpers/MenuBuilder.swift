import UIKit

@resultBuilder
struct MenuBuilder {
  static func buildBlock(_ components: UIMenuElement...) -> [UIMenuElement] {
    components
  }
}

extension UIMenu {
  convenience init(
    title: String = "", systemSymbol: String = "",
    options: Options = .init(), @MenuBuilder children: () -> [UIMenuElement]
  ) {
    self.init(
      title: title, image: systemSymbol.isEmpty ? nil : UIImage(systemName: systemSymbol),
      options: options, children: children())
  }

  static func exportMenu(for request: RequestModel) -> UIMenu {
    UIMenu(title: "Share") {
      UIAction(title: "Text") { _ in self.openShareSheet(item: RequestExporter.txtExport(request: request)) }
      UIAction(title: "Curl") { _ in self.openShareSheet(item: RequestExporter.curlExport(request: request)) }
    }
  }

  static private func openShareSheet(item: Any?) {
    guard let item else { return }
    let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
    UIViewController.currentViewController()?.present(activity, animated: true)
  }
}

extension UIAction {
  convenience init(
    title: String,
    systemSymbol: String = "",
    isOn: Bool = false,
    attributes: UIMenuElement.Attributes = [],
    handler: @escaping (UIAction) -> Void
  ) {
    self.init(
      title: title, image: systemSymbol.isEmpty ? nil : UIImage(systemName: systemSymbol),
      attributes: attributes, state: isOn ? .on : .off, handler: handler
    )
  }
}
