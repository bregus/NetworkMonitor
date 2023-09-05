import UIKit
import SPIndicator

enum Section: Hashable {
  case overview([OverviewItem]), group(SectionItem, BodyItem)
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
  let disclousure: Bool
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

@available(iOS 14, *)
final class DetailViewController: UICollectionViewController {
  private lazy var sections: [Section] = {
    request.method == LogLevel.method ? logSections : requestSections
  }()

  private lazy var requestSections: [Section] = [
    .overview(overview),
    .group(
      SectionItem(icon: "list.bullet.rectangle", title: "Request headers", fields: request.requestHeaders.map { FieldItem(title: $0.key, subtitle: $0.value) }),
      BodyItem(icon: "arrow.up.circle.fill", title: "Request body", body: request.requestBody)),
    .group(
      SectionItem(icon: "list.bullet.rectangle", title: "Response headers", fields: request.responseHeaders.map { FieldItem(title: $0.key, subtitle: $0.value) }),
      BodyItem(icon: "arrow.down.circle.fill", title: "Response body", body: request.responseBody)
    )
  ]

  private lazy var logSections: [Section] = [
    .overview([OverviewItem(title: request.scheme?.uppercased() ?? "", subtitle: request.path ?? request.url, disclousure: false, inline: false)]),
    .group(
      SectionItem(icon: "list.bullet.rectangle", title: "Parameters", fields: request.responseHeaders.map { FieldItem(title: $0.key,subtitle: $0.value) }),
      BodyItem(icon: "cylinder.split.1x2", title: "Metadata", body: request.responseBody)
    )
  ]

  private var overview: [OverviewItem] {
    var items = [OverviewItem]()
    let status = StatusModel(request: request)
    items.append(OverviewItem(icon: status.systemImage, title: status.title, color: status.tint, subtitle: request.duration.formattedMilliseconds.description, disclousure: false))
    items.append(OverviewItem(title: (request.method ?? "") + " " + request.url, disclousure: true))
    if let error = request.errorClientDescription {
      items.append(OverviewItem(title: "Error: \(error.localizedDescription.capitalized)", disclousure: true))
    }
    return items
  }

  private var dataSource: UICollectionViewDiffableDataSource<Section, ListItem>!
  private var request: RequestModel

  // MARK: Cell registration
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
    if sectionItem.disclousure {
      cell.accessories = [.disclosureIndicator()]
    }
  }

  let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SectionItem> {
    (cell, indexPath, sectionItem) in
    var content = cell.defaultContentConfiguration()
    content.text = sectionItem.title
    content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
    content.image = UIImage(systemName: sectionItem.icon)
    content.secondaryText = sectionItem.fields.count.description
    content.secondaryTextProperties.font = .systemFont(ofSize: 16, weight: .medium)
    content.prefersSideBySideTextAndSecondaryText = true
    cell.contentConfiguration = content

    if !sectionItem.fields.isEmpty {
      let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
      cell.accessories = [.outlineDisclosure(options:headerDisclosureOption)]
    }
  }

  let fieldCellConfiguration = UICollectionView.CellRegistration<UICollectionViewListCell, FieldItem> {
    (cell, indexPath, symbolItem) in

    var content = cell.defaultContentConfiguration()
    content.text = symbolItem.title
    content.secondaryText = symbolItem.subtitle
    content.secondaryTextProperties.font = .systemFont(ofSize: 16, weight: .medium)
    content.textProperties.color = .secondaryLabel
    content.textProperties.font = .systemFont(ofSize: 14)
    cell.contentConfiguration = content
  }

  let bodyCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, BodyItem> {
    (cell, indexPath, body) in

    var content = cell.defaultContentConfiguration()
    content.text = body.title
    content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
    content.image = UIImage(systemName: body.icon)
    content.secondaryTextProperties.font = .systemFont(ofSize: 16, weight: .semibold)
    content.secondaryText = body.body?.weight ?? "0 bytes"
    content.prefersSideBySideTextAndSecondaryText = true
    cell.contentConfiguration = content
    if let body = body.body, !body.isEmpty {
      cell.accessories = [.disclosureIndicator(options: .init(tintColor: .systemBlue))]
    }
  }

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
    createDataSource()
    createSnapshot()
  }

  private func setupNavigationItems() {
    let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareContent))
    navigationItem.rightBarButtonItems = [shareButton]
  }

  @objc private func shareContent() {
    let item = RequestExporter.txtExport(request: request)
    let activity = UIActivityViewController(activityItems: [item], applicationActivities: nil)
    present(activity, animated: true)
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
      case .group(let list, let body):
        let sectionListItem = ListItem.header(list)
        sectionSnapshot.append([sectionListItem])
        let symbolListItemArray = list.fields.map { ListItem.field($0) }
        sectionSnapshot.append(symbolListItemArray, to: sectionListItem)
        sectionSnapshot.append([.body(body)])
        if request.method == LogLevel.method {
          sectionSnapshot.expand([sectionListItem])
        }
      }
      dataSource.apply(sectionSnapshot, to: sectionItem, animatingDifferences: false)
    }
  }

  // MARK: Initialize data source
  private func createDataSource() {
    dataSource = UICollectionViewDiffableDataSource<Section, ListItem>(collectionView: collectionView) {
      (collectionView, indexPath, listItem) -> UICollectionViewCell? in
      switch listItem {
      case .overview(let overview):
        return collectionView.dequeueConfiguredReusableCell(using: self.overViewCellRegistration, for: indexPath, item: overview)
      case .header(let sectionItem):
        return collectionView.dequeueConfiguredReusableCell(using: self.headerCellRegistration, for: indexPath, item: sectionItem)
      case .field(let symbolItem):
        return collectionView.dequeueConfiguredReusableCell(using: self.fieldCellConfiguration, for: indexPath, item: symbolItem)
      case .body(let bodyItem):
        return collectionView.dequeueConfiguredReusableCell(using: self.bodyCellRegistration, for: indexPath, item: bodyItem)
      }
    }
  }
}

// MARK: - UICollectionViewDelegate
@available(iOS 14, *)
extension DetailViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    guard let cell = dataSource.itemIdentifier(for: indexPath) else { return }

    if case .field(let fieldItem) = cell {
      let indicator = SPIndicatorView(title: "Copied", preset: .done)
      indicator.presentSide = .bottom
      indicator.present(duration: 1, haptic: .success)
      UIPasteboard.general.string = fieldItem.subtitle
    }

    if case .body(let bodyItem) = cell, let body = bodyItem.body {
      let vc = BodyDetailViewController()
      vc.setBody(body)
      navigationController?.pushViewController(vc, animated: true)
    }

    if case .overview = cell {
      let vc = BodyDetailViewController()
      vc.setText(RequestExporter.txtExport(request: request))
      navigationController?.pushViewController(vc, animated: true)
    }
  }
}
