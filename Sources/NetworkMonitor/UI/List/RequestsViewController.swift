import UIKit
import Combine

enum CategoryType: String, CaseIterable {
  case network
  case log
  case all
}

extension Array where Element == RequestModel {
  enum SortType: String {
    case date, duration
  }

  enum SortOrder {
    case increasing, decreasing
  }

  func filter(_ category: CategoryType) -> Self {
    switch category {
    case .network:
      filter{ $0.method != LogLevel.method }
    case .log:
      filter{ $0.method == LogLevel.method }
    case .all:
      self
    }
  }

  func sort(_ type: SortType, order: SortOrder) -> Self {
    switch type {
    case .date:
      sorted(by: \.date, order: order)
    case .duration:
      sorted(by: \.duration, order: order)
    }
  }

  func sorted<Value: Comparable>(
    by keyPath: KeyPath<Self.Element, Value>,
    order: SortOrder
  ) -> [Self.Element] {
    switch order {
    case .increasing:
      sorted(by: { $0[keyPath: keyPath]  <  $1[keyPath: keyPath] })
    case .decreasing:
      sorted(by: { $0[keyPath: keyPath]  >  $1[keyPath: keyPath] })
    }
  }
}

final public class RequestsViewController: UITableViewController {
  private let searchController = UISearchController(searchResultsController: nil)
  private var filteredRequests: [RequestModel] { filterRequests() }
  private var sortType: Array.SortType = .date {
    didSet {
      settingsBarButton.menu = UIMenu(children: settingsMenu)
      tableView.reloadData()
    }
  }
  private var sortOrder: Array.SortOrder = .decreasing {
    didSet {
      settingsBarButton.menu = UIMenu(children: settingsMenu)
      tableView.reloadData()
    }
  }
  private var categoryType: CategoryType {
    CategoryType.allCases[self.searchController.searchBar.selectedScopeButtonIndex]
  }
  private var store = Set<AnyCancellable>()

  @MenuBuilder private var settingsMenu: [UIMenuElement] {
    UIMenu(title: "Sort", systemSymbol: "arrow.up.arrow.down") {
      UIMenu(options: .displayInline) {
        UIAction(title: "Date", isOn: sortType == .date) { _ in self.sortType = .date }
        UIAction(title: "Duration", isOn: sortType == .duration) { _ in self.sortType = .duration }
      }
      UIMenu(options: .displayInline) {
        UIAction(title: "Increasing", isOn: sortOrder == .increasing) { _ in self.sortOrder = .increasing }
        UIAction(title: "Decreasing", isOn: sortOrder == .decreasing) { _ in self.sortOrder = .decreasing }
      }
    }
    UIAction(title: "Clear", systemSymbol: "eraser.fill", attributes: .destructive) { _ in Storage.shared.clearRequests() }
  }

  private lazy var settingsBarButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: nil)

  public override func viewDidLoad() {
    super.viewDidLoad()
    title = "Console"

    addNavigationItems()
    addSearchController()
    addKeyboardToolbar()

    tableView.registerCell(RequestCell.self)
    tableView.registerCell(LogRequestCell.self)

    NotificationCenter.default.publisher(for: .newRequestNotification)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        self.updateSegments()
        self.tableView.reloadData()
      }
      .store(in: &store)
  }

  //  MARK: - Search
  private func addSearchController(){
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.automaticallyShowsScopeBar = true
    searchController.searchBar.showsScopeBar = true
    searchController.searchBar.placeholder = "Search"
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.searchController = searchController
    definesPresentationContext = true
    updateSegments()
  }

  private func updateSegments() {
    searchController.searchBar.scopeButtonTitles = CategoryType.allCases.map { "\($0.rawValue.capitalized)(\(Storage.shared.requests.filter($0).count))" }
  }

  private func filterRequests() -> [RequestModel] {
    let filterCategory: () -> [RequestModel] = {
      Storage.shared.requests.filter(self.categoryType).sort(self.sortType, order: self.sortOrder)
    }
    guard let searchText = searchController.searchBar.text, !searchText.isEmpty else { return filterCategory() }
    return filterCategory()
      .filter {
        $0.url.range(of: searchText, options: .caseInsensitive) != nil
        || $0.method?.range(of: searchText, options: .caseInsensitive) != nil
        || $0.scheme?.range(of: searchText, options: .caseInsensitive) != nil
        || $0.host?.range(of: searchText, options: .caseInsensitive) != nil
        || ($0.code == Int(searchText) && $0.code != -1)
        || $0.responseContentType?.rawValue.range(of: searchText, options: .caseInsensitive) != nil
      }
  }

  private func addKeyboardToolbar() {
    let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 44.0))
    let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let barButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone))
    toolBar.setItems([flexible, barButton], animated: false)
    searchController.searchBar.inputAccessoryView = toolBar
  }

  // MARK: - Actions
  @objc private func tapDone() {
    searchController.searchBar.endEditing(true)
  }

  // MARK: - Navigation
  private func addNavigationItems() {
    navigationItem.rightBarButtonItem = settingsBarButton
    settingsBarButton.menu = UIMenu(children: settingsMenu)
  }

  private func openRequestDetailVC(request: RequestModel) {
    if request.method == LogLevel.method {
      let vc = BodyDetailViewController()
      vc.setText(RequestExporter.logExport(request: request))
      presentAsSheet(vc)
    } else {
      navigationController?.pushViewController(DetailViewController(request: request), animated: true)
    }
  }
}

// MARK: - UITableViewDataSource
extension RequestsViewController {
  public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    filteredRequests.count
  }

  public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let request = filteredRequests[indexPath.item]
    if request.method == LogLevel.method {
      let cell = tableView.dequeueCell(LogRequestCell.self, for: indexPath)
      cell.configure(with: request)
      cell.accessoryType = .disclosureIndicator
      return cell
    } else {
      let cell = tableView.dequeueCell(RequestCell.self, for: indexPath)
      cell.configure(with: request)
      cell.accessoryType = .disclosureIndicator
      return cell
    }
  }

  public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
}

// MARK: - UITableViewDelegate
extension RequestsViewController {
  public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    openRequestDetailVC(request: filteredRequests[indexPath.item])
    tableView.deselectRow(at: indexPath, animated: true)
  }

  public override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let request = filteredRequests[indexPath.item]
    let actionProvider: UIContextMenuActionProvider = { _ in
      UIMenu {
        UIMenu.exportMenu(for: request)
        UIAction(title: "Copy URL") { _ in UIPasteboard.general.string = request.url }
        UIAction(title: "Delete", attributes: .destructive) { _ in Storage.shared.deleteRequest(request) }
      }
    }
    return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: { () -> UIViewController? in
      let vc = PreviewController()
      vc.setText(RequestExporter.txtExport(request: request, short: true))
      return nil
    }, actionProvider: actionProvider)
  }

  public override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
    animator.addCompletion {
      guard let index = configuration.identifier as? IndexPath else { return }
      self.openRequestDetailVC(request: self.filteredRequests[index.item])
    }
  }
}

// MARK: - UISearchResultsUpdating
extension RequestsViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    tableView.reloadData()
  }
}
