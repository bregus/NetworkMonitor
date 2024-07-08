//
//  UIViewController.swift
//  
//
//  Created by Рома Сумороков on 04.04.2023.
//

import UIKit

extension UIViewController {

  static func currentViewController(
    _ viewController: UIViewController? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController) -> UIViewController?
  {
    guard let viewController = viewController else { return nil }

    if let viewController = viewController as? UINavigationController {
      if let viewController = viewController.visibleViewController {
        return currentViewController(viewController)
      } else {
        return currentViewController(viewController.topViewController)
      }
    } else if let viewController = viewController as? UITabBarController {
      if let viewControllers = viewController.viewControllers, viewControllers.count > 5, viewController.selectedIndex >= 4 {
        return currentViewController(viewController.moreNavigationController)
      } else {
        return currentViewController(viewController.selectedViewController)
      }
    } else if let viewController = viewController.presentedViewController {
      return currentViewController(viewController)
    } else if viewController.children.count > 0 {
      return viewController.children[0]
    } else {
      return viewController
    }
  }

  var embedded: UIViewController {
    UINavigationController(rootViewController: self)
  }

  func presentAsSheet(_ controller: UIViewController) {
    if #available(iOS 15.0, *) {
      let nav = controller.embedded
      nav.sheetPresentationController?.detents = [.medium(), .large()]
      present(nav, animated: true)
    } else {
      navigationController?.pushViewController(controller, animated: true)
    }
  }
}
