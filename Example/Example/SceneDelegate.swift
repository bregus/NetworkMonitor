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
    NetworkMonitor.enableAutomaticRegistration()
    sendRequests()

    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = UINavigationController(rootViewController: RequestsViewController())
    self.window = window
    window.makeKeyAndVisible()
  }

  func sendRequests() {
    let just = JustOf<HTTP>(session: .shared)
    just.post("https://jsonplaceholder.typicode.com/posts", data: ["ку": "rey"], headers: ["content-type": "application/json"], asyncCompletionHandler: { _ in })
    just.post("https://jsonplaceholder.typicode.com/posts", data: ["r": "e"], headers: ["content-type": "application/json"], asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/posts", data: ["r": "e"], headers: ["content-type": "application/json"], asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/posts/1", asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/posts/1/comments", asyncCompletionHandler: { _ in })
    just.get("https://github.com/CreateAPI/Get", asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/users", asyncCompletionHandler: { _ in })
    just.get("https://jsonplaceholder.typicode.com/photos", asyncCompletionHandler: { _ in })
    just.get("http://172.23.0.2:8096/Shows/NextUp?userId=972692f619e043fe8d959bdc3580b614&limit=1", timeout: 5, asyncCompletionHandler: { _ in })
    just.get("https://images.unsplash.com/photo-1696237983389-8ff5b15d3430?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxlZGl0b3JpYWwtZmVlZHwzOHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=900&q=60", asyncCompletionHandler: { _ in })
    just.get("http://msp1-chel2.is74.ru:3101/v1/contacts", asyncCompletionHandler: { _ in })

    let just2 = JustOf<HTTP>(session: URLSession(configuration: URLSessionConfiguration.default))
    just2.get("https://cdn.cams.is74.ru/snapshot?uuid=8065952c-84b4-47ff-af55-b70ed40e261f&lossy=1&token=bearer-9649662e9a6f9af1b719b99518b070cd", asyncCompletionHandler: { _ in })

    NetworkMonitor.log(level: .debug(message: "all requests sent"))
  }
}
