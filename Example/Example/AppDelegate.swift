//
//  AppDelegate.swift
//  Example
//
//  Created by Рома Сумороков on 14.10.2023.
//

import UIKit
import NetworkMonitor

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    NetworkMonitor.log(level: .debug(message: "didFinishLaunchingWithOptions"), label: "Application")
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    NetworkMonitor.log(level: .debug(message: "configurationForConnecting"), label: "Application")
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    NetworkMonitor.log(level: .debug(message: "didDiscardSceneSessions"), label: "Application")
  }


}

