//
//  SceneDelegate.swift
//  Example
//
//  Created by Рома Сумороков on 14.10.2023.
//

import UIKit
import NetworkMonitor
import Just

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    URLProtocol.registerClass(NetwrokListenerUrlProtocol.self)
    sendRequests()

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = UINavigationController(rootViewController: RequestsViewController())
    self.window = window
    window.makeKeyAndVisible()
  }

  func sendRequests() {
    let just = JustOf<HTTP>(session: .shared)
    just.post("https://jsonplaceholder.typicode.com/posts", data: ["r": "e"], headers: ["content-type": "application/json"], asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/posts", data: ["r": "e"], headers: ["content-type": "application/json"], asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/posts/1", asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/posts/1/comments", asyncCompletionHandler: { _ in })
    just.get("https://github.com/CreateAPI/Get", asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/users", asyncCompletionHandler: { _ in })
//    just.get("https://jsonplaceholder.typicode.com/photos", asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com//photos", asyncCompletionHandler: { _ in })
    just.get("https://images.unsplash.com/photo-1696237983389-8ff5b15d3430?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwzOHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=900&q=60", asyncCompletionHandler: { _ in })
    NetworkMonitor.shared.log(level: .debug(message: "all requests sent"), label: "Network")
  }
}
