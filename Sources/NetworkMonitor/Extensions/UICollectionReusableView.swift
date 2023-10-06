//
//  UICollectionReusableView.swift
//  
//
//  Created by Рома Сумороков on 04.04.2023.
//

import UIKit

extension UICollectionView {
  func registerCell<Cell: UICollectionViewCell>(_ cell: Cell.Type) {
    register(Cell.self, forCellWithReuseIdentifier: reuseIdentifier(for: cell))
  }

  private func reuseIdentifier<T>(for reuse: T.Type) -> String {
    String(describing: reuse)
  }

  func dequeueCell<Cell: UICollectionViewCell>(_ cell: Cell.Type, for indexPath: IndexPath) -> Cell {
    if let cell = dequeueReusableCell(withReuseIdentifier: String(describing: cell), for: indexPath) as? Cell {
      return cell
    }
    return Cell()
  }
}

extension UITableView {
  func registerCell<Cell: UITableViewCell>(_ cell: Cell.Type) {
    register(Cell.self, forCellReuseIdentifier: reuseIdentifier(for: cell))
  }

  private func reuseIdentifier<T>(for reuse: T.Type) -> String {
    String(describing: reuse)
  }

  func dequeueCell<Cell: UITableViewCell>(_ cell: Cell.Type, for indexPath: IndexPath) -> Cell {
    if let cell = dequeueReusableCell(withIdentifier: String(describing: cell), for: indexPath) as? Cell {
      return cell
    }
    return Cell()
  }
}
