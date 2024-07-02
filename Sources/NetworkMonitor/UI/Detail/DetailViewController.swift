import UIKit
import Combine

final class DetailViewController: UICollectionViewController {
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

  let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderItem> {
    (cell, indexPath, sectionItem) in
    var content = UIListContentConfiguration.valueCell()
    content.text = sectionItem.title
    content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
    content.image = UIImage(systemName: sectionItem.icon)
    content.secondaryText = sectionItem.headers.count.description
    cell.contentConfiguration = content

    if !sectionItem.headers.isEmpty {
      cell.accessories = [.disclosureIndicator(options: .init(tintColor: .systemBlue))]
    }
  }

  let bodyCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, BodyItem> {
    (cell, indexPath, body) in

    var content = UIListContentConfiguration.valueCell()
    content.text = body.title
    content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
    content.image = UIImage(systemName: body.icon)
    content.secondaryText = body.body?.weight ?? "0 bytes"
    cell.contentConfiguration = content
    if let body = body.body, !body.isEmpty {
      cell.accessories = [.disclosureIndicator(options: .init(tintColor: .systemBlue))]
    }
  }

  private var sections: [Section] {[
    .overview(overview),
    .group([
      .header(HeaderItem(
        icon: "list.bullet.rectangle",
        title: "Request headers",
        headers: request.requestHeaders
      )),
      .body(BodyItem(
        icon: "arrow.up.circle.fill",
        title: "Request body",
        body: request.requestBody)
      )
    ]),
    .group([
      .header(HeaderItem(
        icon: "list.bullet.rectangle",
        title: "Response headers",
        headers: request.responseHeaders
      )),
      .body(BodyItem(
        icon: "arrow.down.circle.fill",
        title: "Response body",
        body: request.responseBody)
      )
    ])
  ]}

  private var overview: [OverviewItem] {
    var items = [OverviewItem]()
    let status = StatusModel(request: request)
    items.append(OverviewItem(
      icon: status.systemImage,
      title: status.title,
      color: status.tint,
      subtitle: request.duration.formattedMilliseconds.description,
      disclosure: false, type: .status)
    )
    items.append(OverviewItem(title: (request.method ?? "") + " " + request.url, disclosure: true, type: .url))
    if let error = request.error {
      items.append(OverviewItem(
        title: "Error: \(error.localizedDescription.capitalized)",
        disclosure: true, type: .error)
      )
    }
    if let metrics = request.metrics {
      items.append(OverviewItem(
        icon: "chart.pie.fill",
        title: "Metrics",
        color: .systemOrange,
        subtitle: metrics.totalTransferSize.totalBytes,
        disclosure: true, type: .metrics)
      )
    }
    return items
  }

  private lazy var dataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) {
    (collectionView, indexPath, listItem) -> UICollectionViewCell? in
    switch listItem {
    case .overview(let overview):
      return collectionView.dequeueConfiguredReusableCell(using: self.overViewCellRegistration, for: indexPath, item: overview)

    case .header(let sectionItem):
      return collectionView.dequeueConfiguredReusableCell(using: self.headerCellRegistration, for: indexPath, item: sectionItem)

    case .body(let bodyItem):
      return collectionView.dequeueConfiguredReusableCell(using: self.bodyCellRegistration, for: indexPath, item: bodyItem)
    }
  }

  private var request: RequestModel
  private var store = Set<AnyCancellable>()

  init(request: RequestModel) {
    let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
    self.request = request
    super.init(collectionViewLayout: listLayout)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = request.path
    setupNavigationItems()
    createSnapshot()

    NotificationCenter.default.publisher(for: .newRequestNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self, let updated = Storage.shared.requests.first(where: { $0.id == self.request.id && $0 != self.request }) else { return }
        self.request = updated
        self.createSnapshot()
      }
      .store(in: &store)
  }

  private func setupNavigationItems() {
    let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)
    navigationItem.rightBarButtonItem = shareButton
    shareButton.menu = ExportMenuBuilder(title: "Export")
      .export(title: "Text", export: RequestExporter.txtExport(request: request))
      .export(title: "Curl", export: RequestExporter.curlExport(request: request))
      .build()
  }

  // MARK: - Setup snapshots
  private func createSnapshot() {
    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, ListItem>()
    dataSourceSnapshot.appendSections(sections)
    dataSource.apply(dataSourceSnapshot)

    for sectionItem in sections {
      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()

      switch sectionItem {
      case .overview(let item):
        sectionSnapshot.append(item.map { ListItem.overview($0)})
      case .group(let items):
        sectionSnapshot.append(items)
      }
      dataSource.apply(sectionSnapshot, to: sectionItem, animatingDifferences: false)
    }
  }
}

// MARK: - UICollectionViewDelegate
extension DetailViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    guard let cell = dataSource.itemIdentifier(for: indexPath) else { return }
    let vc = BodyDetailViewController()

    switch cell {
    case .header(let item):
      if item.headers.isEmpty { return }
      vc.setText(.render(item.headers.map {($0.key, $0.value)}))
      vc.title = "Headers"
    case .body(let item):
      if let body = item.body { vc.setBody(body); vc.title = "Body" } else { return }
    case .overview(let overview):
      switch overview.type {
      case .url: 
        vc.setText(RequestExporter.txtExport(request: request))
        vc.title = "Overview"
      case .error:
        vc.setText(ErrorFormatter.description(error: request.error!))
        vc.title = "Error"
      case .metrics:
        guard let metrics = request.metrics else { return }
        vc.setText(MetricsExporter.transactionDetail(metrics: metrics))
        vc.title = "Metrics"
      default: return
      }
    }

    presentAsSheet(vc)
  }
}
