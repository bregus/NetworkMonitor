import UIKit
import SPIndicator

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

  let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SectionItem> {
    (cell, indexPath, sectionItem) in
    var content = UIListContentConfiguration.valueCell()
    content.text = sectionItem.title
    content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
    content.image = UIImage(systemName: sectionItem.icon)
    content.secondaryText = sectionItem.fields.count.description
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


  private lazy var sections: [Section] = {
    request.method == LogLevel.method ? logSections : requestSections
  }()

  private lazy var requestSections: [Section] = [
    .overview(overview),
    .group([
      .header(SectionItem(
        icon: "list.bullet.rectangle",
        title: "Request headers",
        fields: request.requestHeaders.map { FieldItem(title: $0.key, subtitle: $0.value) }
      )),
      .body(BodyItem(
        icon: "arrow.up.circle.fill",
        title: "Request body",
        body: request.requestBody)
      )
    ]),
    .group([
      .header(SectionItem(
        icon: "list.bullet.rectangle",
        title: "Response headers",
        fields: request.responseHeaders.map { FieldItem(title: $0.key, subtitle: $0.value) }
      )),
      .body(BodyItem(
        icon: "arrow.down.circle.fill",
        title: "Response body",
        body: request.responseBody)
      )
    ])
  ]

  private lazy var logSections: [Section] = [
    .overview([OverviewItem(
      title: request.scheme?.uppercased() ?? "",
      subtitle: request.path ?? request.url,
      disclosure: false, inline: false)
    ]),
    .group([
      .header(SectionItem(
        icon: "list.bullet.rectangle",
        title: "Parameters",
        fields: request.responseHeaders.map { FieldItem(title: $0.key,subtitle: $0.value) }
      )),
      .body(BodyItem(
        icon: "cylinder.split.1x2",
        title: "Metadata",
        body: request.responseBody
      ))
    ])
  ]

  private var overview: [OverviewItem] {
    var items = [OverviewItem]()
    let status = StatusModel(request: request)
    items.append(OverviewItem(icon: status.systemImage, title: status.title, color: status.tint, subtitle: request.duration.formattedMilliseconds.description, disclosure: false))
    items.append(OverviewItem(title: (request.method ?? "") + " " + request.url, disclosure: true))
    if let error = request.errorClientDescription {
      items.append(OverviewItem(title: "Error: \(error.localizedDescription.capitalized)", disclosure: true))
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

    case .field(let symbolItem):
      return collectionView.dequeueConfiguredReusableCell(using: self.fieldCellConfiguration, for: indexPath, item: symbolItem)

    case .body(let bodyItem):
      return collectionView.dequeueConfiguredReusableCell(using: self.bodyCellRegistration, for: indexPath, item: bodyItem)
    }
  }

  private let request: RequestModel

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
      case .group(let items):
        sectionSnapshot.append(items)
        items.forEach { item in
          guard case .header(let fields) = item else { return }
          sectionSnapshot.append(fields.fields.map(ListItem.field), to: item)
          if request.method == LogLevel.method {
            sectionSnapshot.expand([item])
          }
        }
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

    if case .field(let fieldItem) = cell {
      let indicator = SPIndicatorView(title: "Copied", preset: .done)
      indicator.presentSide = .bottom
      indicator.present(duration: 1, haptic: .success)
      UIPasteboard.general.string = fieldItem.subtitle
    }

    if case .body(let bodyItem) = cell, let body = bodyItem.body, !body.isEmpty {
      let vc = BodyDetailViewController()
      vc.setBody(body)
      navigationController?.pushViewController(vc, animated: true)
    }

    if case .overview(let item) = cell, item.disclosure {
      let vc = BodyDetailViewController()
      vc.setText(RequestExporter.txtExport(request: request))
      navigationController?.pushViewController(vc, animated: true)
    }
  }
}
