//
//  Entities.swift
//  
//
//  Created by Рома Сумороков on 07.10.2023.
//

import UIKit

enum Section: Hashable {
  case overview([OverviewItem]), group([ListItem])
}

enum ListItem: Hashable {
  case overview(OverviewItem)
  case header(HeaderItem)
  case body(BodyItem)
}

struct HeaderItem: Hashable {
  var icon: String = ""
  let title: String
  let headers: [String: String]
}

struct OverviewItem: Hashable {
  enum ItemType {
    case status, url, error, metrics
  }

  var icon: String = ""
  let title: String
  var color: UIColor = .label
  var subtitle: String = ""
  let disclosure: Bool
  var inline: Bool = true
  var type: ItemType
}

struct BodyItem: Hashable {
  var icon: String = ""
  var title: String
  let body: Data?
}
