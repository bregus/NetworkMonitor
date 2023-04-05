import UIKit

enum ListItem: Hashable {
  case header(HeaderItem)
  case field(FieldItem)
  case body(BodyItem)
}

struct HeaderItem: Hashable {
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
  lazy var modelObjects = [
    HeaderItem(title: "Overview", fields: request.overview().map { .field(FieldItem(title: $0.key, subtitle: $0.value)) } ),
    HeaderItem(title: "Request headers", fields: request.headers.map { .field(FieldItem(title: $0.key, subtitle: $0.value)) }),
    HeaderItem(title: "Request body", fields: [.body(BodyItem(body: request.httpBody))]),
    HeaderItem(title: "Response Headers", fields: request.responseHeaders.map { .field(FieldItem(title: $0.key, subtitle: $0.value)) }),
    HeaderItem(title: "Response body", fields: [.body(BodyItem(body: request.responseBody))])
  ]

  var dataSource: UICollectionViewDiffableDataSource<HeaderItem, ListItem>!
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

    self.title = request.pathComponents

    // MARK: Cell registration
    let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, HeaderItem> {
      (cell, indexPath, headerItem) in

      // Set headerItem's data to cell
      var content = cell.defaultContentConfiguration()
      content.text = headerItem.title
      content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
      cell.contentConfiguration = content

      // Add outline disclosure accessory
      // With this accessory, the header cell's children will expand / collapse when the header cell is tapped.
      if !headerItem.fields.isEmpty {
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
    dataSource = UICollectionViewDiffableDataSource<HeaderItem, ListItem>(collectionView: collectionView) {
      (collectionView, indexPath, listItem) -> UICollectionViewCell? in

      switch listItem {
      case .header(let headerItem):
        let cell = collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration,
                                                                for: indexPath,
                                                                item: headerItem)
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
    var dataSourceSnapshot = NSDiffableDataSourceSnapshot<HeaderItem, ListItem>()

    // Create collection view section based on number of HeaderItem in modelObjects
    dataSourceSnapshot.appendSections(modelObjects)
    dataSource.apply(dataSourceSnapshot)

    // Loop through each header item so that we can create a section snapshot for each respective header item.
    for headerItem in modelObjects {

      // Create a section snapshot
      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()

      // Create a header ListItem & append as parent
      let headerListItem = ListItem.header(headerItem)
      sectionSnapshot.append([headerListItem])

      // Create an array of symbol ListItem & append as child of headerListItem
      let symbolListItemArray = headerItem.fields.map { $0 }
      sectionSnapshot.append(symbolListItemArray, to: headerListItem)

      // Expand this section by default
      if headerItem.title == "Overview" { sectionSnapshot.expand([headerListItem]) }

      // Apply section snapshot to the respective collection view section
      dataSource.apply(sectionSnapshot, to: headerItem, animatingDifferences: false)
    }
  }
}

@available(iOS 14, *)
extension DetailViewController {
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let body = dataSource.itemIdentifier(for: indexPath) else {
      collectionView.deselectItem(at: indexPath, animated: true)
      return
    }
    if case .body(let bodyItem) = body, let body = bodyItem.body {
      let vc = BodyDetailViewController()
      vc.setBody(body)
      navigationController?.pushViewController(vc, animated: true)
    }
  }
}
