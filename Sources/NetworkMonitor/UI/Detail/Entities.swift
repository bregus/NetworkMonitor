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
  case header(SectionItem)
  case field(FieldItem)
  case body(BodyItem)
}

struct SectionItem: Hashable {
  var icon: String = ""
  let title: String
  let fields: [FieldItem]
}

struct OverviewItem: Hashable {
  var icon: String = ""
  let title: String
  var color: UIColor = .label
  var subtitle: String = ""
  let disclosure: Bool
  var inline: Bool = true
}

struct FieldItem: Hashable {
  let title: String
  let subtitle: String
}

struct BodyItem: Hashable {
  var icon: String = ""
  var title: String
  let body: Data?
}
