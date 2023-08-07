import UIKit
import SPIndicator

enum ListItem: Hashable {
  case overview(SectionItem)
  case header(SectionItem)
  case field(FieldItem)
  case body(BodyItem)
}

struct SectionItem: Hashable {
  let icon: String
  let title: String
  let fields: [ListItem]
}

struct FieldItem: Hashable {
  let title: String
  let subtitle: String
}

struct BodyItem: Hashable {
  let body: Data?
}

@available(iOS 14, *)
final class DetailViewController: UICollectionViewController {
  var objects: [SectionItem] {
    request.scheme == LogLevel.analytic.rawValue ? logModelObjects : modelObjects
  }

  lazy var modelObjects = [
    SectionItem(icon: "eye.square", title: "Overview", fields: request.overview().map { .field(FieldItem(title: $0.key, subtitle: $0.value)) } ),
    SectionItem(icon: "list.bullet.rectangle", title: "Request headers", fields: request.requestHeaders.map { .field(FieldItem(title: $0.key, subtitle: $0.value)) }),
    SectionItem(icon: "arrow.up.circle.fill", title: "Request body", fields: [.body(BodyItem(body: request.requestBody))]),
    SectionItem(icon: "list.bullet.rectangle", title: "Response Headers", fields: request.responseHeaders.map { .field(FieldItem(title: $0.key, subtitle: $0.value)) }),
    SectionItem(icon: "arrow.down.circle.fill", title: "Response body", fields: [.body(BodyItem(body: request.responseBody))])
  ]

  lazy var logModelObjects = [
    SectionItem(icon: "", title: "Log", fields: [.field(FieldItem(title: "", subtitle: request.host ?? ""))]),
    SectionItem(icon: "", title: "Events", fields: (request.requestHeaders).map { .field(FieldItem(title: $0.key, subtitle: String(describing: $0.value))) }),
    SectionItem(icon: "", title: "Parameters", fields: (request.responseBody?.dict ?? [:]).map { .field(FieldItem(title: $0.key, subtitle: String(describing: $0.value))) })
  ]

  var dataSource: UICollectionViewDiffableDataSource<SectionItem, ListItem>!
  var request: RequestRepresentable

  init(request: RequestRepresentable) {
    let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    //    layoutConfig.headerMode = .firstItemInSection
    let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
    self.request = request
    super.init(collectionViewLayout: listLayout)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = request.path

    // MARK: Cell registration
    let overViewCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SectionItem> {
      (cell, indexPath, sectionItem) in

      // Set sectionItem's data to cell
      var content = cell.defaultContentConfiguration()
      content.text = sectionItem.title
      content.textProperties.font = .systemFont(ofSize: 14, weight: .medium)
      content.image = UIImage(systemName: sectionItem.icon)
      cell.contentConfiguration = content
//      cell.accessories = [.disclosureIndicator()]
    }

    let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SectionItem> {
      (cell, indexPath, sectionItem) in

      // Set sectionItem's data to cell
      var content = cell.defaultContentConfiguration()
      content.text = sectionItem.title
      content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
      content.image = UIImage(systemName: sectionItem.icon)
      cell.contentConfiguration = content

      // Add outline disclosure accessory
      // With this accessory, the header cell's children will expand / collapse when the header cell is tapped.
      if !sectionItem.fields.isEmpty {
        let headerDisclosureOption = UICellAccessory.OutlineDisclosureOptions(style: .header)
        cell.accessories = [.outlineDisclosure(options:headerDisclosureOption)]
      }
    }

    let symbolCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FieldItem> {
      (cell, indexPath, symbolItem) in

      // Set symbolItem's data to cell
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

      // Set symbolItem's data to cell
      var content = cell.defaultContentConfiguration()
      content.text = "Open body"
      content.textProperties.color = body.body == nil ? .secondaryLabel : .systemBlue
      content.textProperties.alignment = .center
      cell.contentConfiguration = content
    }

    // MARK: Initialize data source
    dataSource = UICollectionViewDiffableDataSource<SectionItem, ListItem>(collectionView: collectionView) {
      (collectionView, indexPath, listItem) -> UICollectionViewCell? in

      switch listItem {
      case .overview(let overview):
        let cell = collectionView.dequeueConfiguredReusableCell(using: overViewCellRegistration,
                                                                for: indexPath,
                                                                item: overview)
        return cell
      case .header(let sectionItem):
        let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration,
                                                                for: indexPath,
                                                                item: sectionItem)
        return cell
      case .field(let symbolItem):
        let cell = collectionView.dequeueConfiguredReusableCell(using: symbolCellRegistration,
                                                                for: indexPath,
                                                                item: symbolItem)
        return cell
      case .body(let bodyItem):
        let cell = collectionView.dequeueConfiguredReusableCell(using: bodyCellRegistration,
                                                                for: indexPath,
                                                                item: bodyItem)
        return cell
      }
    }

    // MARK: Setup snapshots
    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<SectionItem, ListItem>()

    // Create collection view section based on number of sectionItem in modelObjects
    dataSourceSnapshot.appendSections(objects)
    dataSource.apply(dataSourceSnapshot)

    // Loop through each header item so that we can create a section snapshot for each respective header item.
    for (index, sectionItem) in objects.enumerated() {

      // Create a section snapshot
      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()

      // Create a header ListItem & append as parent
      let sectionListItem = index == 0 ? ListItem.overview(sectionItem) : ListItem.header(sectionItem)
      sectionSnapshot.append([sectionListItem])

      // Create an array of symbol ListItem & append as child of sectionListItem
      let symbolListItemArray = sectionItem.fields.map { $0 }
      sectionSnapshot.append(symbolListItemArray, to: sectionListItem)

      // Expand this section by default
      if index == 0 || request.scheme == LogLevel.analytic.rawValue { sectionSnapshot.expand([sectionListItem]) }
      // Apply section snapshot to the respective collection view section
      dataSource.apply(sectionSnapshot, to: sectionItem, animatingDifferences: false)
    }
  }
}

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
  }
}
