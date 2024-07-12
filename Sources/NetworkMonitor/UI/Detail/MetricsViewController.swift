//
//  MetricsViewController.swift
//
//
//  Created by Рома Сумороков on 13.07.2024.
//

import UIKit

final class MetricsViewController: UICollectionViewController {
  let overViewCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OverviewItem> {
    (cell, indexPath, sectionItem) in
    var content = cell.defaultContentConfiguration()
    content.text = sectionItem.title
    content.textProperties.font = .systemFont(ofSize: 14, weight: .medium)
    content.image = UIImage(systemName: sectionItem.icon)
    content.imageProperties.tintColor = sectionItem.color
    content.textProperties.color = sectionItem.color
    content.secondaryText = sectionItem.subtitle
    content.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .regular)
    content.prefersSideBySideTextAndSecondaryText = sectionItem.inline
    cell.contentConfiguration = content
    if sectionItem.disclosure {
      cell.accessories = [.disclosureIndicator()]
    }
  }

  private var metrics: Metrics

  private func transactionItems(from transaction: TransactionMetrics) -> [OverviewItem] {
    var items = [OverviewItem]()
    let status = StatusModel(request: transaction.request)
    items.append(OverviewItem(
      icon: status.systemImage,
      title: status.title,
      color: status.tint,
      subtitle: transaction.timing.duration?.formattedMilliseconds.description ?? "",
      disclosure: false, type: .status)
    )
    items.append(OverviewItem(title: (transaction.request.method ?? "") + " " + transaction.request.url, disclosure: true, type: .url))

    items.append(OverviewItem(
      title: transaction.fetchType.title,
      subtitle: transaction.transferSize.totalBytes,
      disclosure: true, inline: false, type: .metrics)
    )
    return items
  }

  private lazy var dataSource = UICollectionViewDiffableDataSource<Int, OverviewItem>(collectionView: collectionView) {
    (collectionView, indexPath, item) -> UICollectionViewCell? in
    collectionView.dequeueConfiguredReusableCell(using: self.overViewCellRegistration, for: indexPath, item: item)
  }

  init(metrics: Metrics) {
    let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
    self.metrics = metrics
    super.init(collectionViewLayout: listLayout)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Metrics"
    createSnapshot()
  }

  // MARK: - Setup snapshots
  private func createSnapshot() {
    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<Int, OverviewItem>()
    for (index, transaction) in metrics.transactions.enumerated() {
      dataSourceSnapshot.appendSections([index])
      dataSourceSnapshot.appendItems(transactionItems(from: transaction), toSection: index)
    }
    dataSource.apply(dataSourceSnapshot)
  }
}

// MARK: - UICollectionViewDelegate
extension MetricsViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    guard let cell = dataSource.itemIdentifier(for: indexPath) else { return }
    let vc = BodyDetailViewController()

    switch cell.type {
    case .url:
      vc.setText(RequestExporter.txtExport(request: metrics.transactions[indexPath.section].request))
      vc.title = "Overview"
    case .metrics:
      vc.setText(MetricsExporter.transactionDetail(transaction: metrics.transactions[indexPath.section]))
      vc.title = "Transaction Details"
    default: return
    }
    presentAsSheet(vc)
  }
}

