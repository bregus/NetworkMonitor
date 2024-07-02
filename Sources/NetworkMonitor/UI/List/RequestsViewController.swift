import UIKit
import Combine

final public class RequestsViewController: UITableViewController {
  private let searchController = UISearchController(searchResultsController: nil)
  private var filteredRequests: [RequestModel] { filterRequests() }
  private var store = Set<AnyCancellable>()

  public override func viewDidLoad() {
    super.viewDidLoad()
    title = "Console"

    addNavigationItems()
    addSearchController()
    addKeyboardToolbar()
    navigationItem.largeTitleDisplayMode = .never

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

  private func updateSegments() {
    searchController.searchBar.scopeButtonTitles = FilterType.allCases.map { "\($0.rawValue.capitalized)(\($0.filter().count))" }
  }

  //  MARK: - Search
  private func addSearchController(){
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.automaticallyShowsScopeBar = true
    searchController.searchBar.barStyle = .default
    searchController.searchBar.showsScopeBar = true
    searchController.searchBar.placeholder = "Search"
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.searchController = searchController
    definesPresentationContext = true
    updateSegments()
  }

  private func filterRequests() -> [RequestModel] {
    guard let searchText = searchController.searchBar.text, !searchText.isEmpty else { return filterCategory() }
    return filterCategory()
      .filter {
        $0.url.range(of: searchText, options: .caseInsensitive) != nil
        || $0.method?.range(of: searchText, options: .caseInsensitive) != nil
        || $0.scheme?.range(of: searchText, options: .caseInsensitive) != nil
        || $0.host?.range(of: searchText, options: .caseInsensitive) != nil
        || ($0.code == Int(searchText) && $0.code != -1)
      }
  }

  private func filterCategory() -> [RequestModel] {
    FilterType.allCases[searchController.searchBar.selectedScopeButtonIndex].filter()
  }

  private func addKeyboardToolbar() {
    let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 44.0))
    let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let barButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone))
    toolBar.setItems([flexible, barButton], animated: false)
    searchController.searchBar.inputAccessoryView = toolBar
  }

  // MARK: - Actions
  private func clearRequests() {
    Storage.shared.clearRequests()
  }

  @objc private func tapDone() {
    self.searchController.searchBar.endEditing(true)
  }

  // MARK: - Navigation
  private func addNavigationItems() {
    let gearItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: nil)

    let clearAction: UIAction = UIAction(title: "Clear", image: UIImage(systemName: "eraser.fill"), attributes: .destructive) { _ in
      self.clearRequests()
    }

    let menu = UIMenu(title: "", children: [clearAction])

    navigationItem.rightBarButtonItem = gearItem
    gearItem.menu = menu
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

  public override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let request = filteredRequests[indexPath.item]
    let actionProvider: UIContextMenuActionProvider = { _ in
      return ExportMenuBuilder()
        .export(title: "Export", export: RequestExporter.txtExport(request: request))
        .append(title: "Copy URL") { _ in UIPasteboard.general.string = request.url }
        .build()
    }
    return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: { () -> UIViewController? in
      let vc = PreviewController()
      vc.setText(RequestExporter.txtExport(request: request, short: true))
      return vc
    }, actionProvider: actionProvider)
  }

  public override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
    animator.addCompletion {
      guard let index = configuration.identifier as? IndexPath else { return }
      self.openRequestDetailVC(request: self.filteredRequests[index.item])
    }
  }
}


extension RequestsViewController {
  public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    filteredRequests.count
  }

  public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let request = filteredRequests[indexPath.item]
    if request.method == LogLevel.method {
      let cell = tableView.dequeueCell(LogRequestCell.self, for: indexPath)
      cell.populate(request: request)
      cell.accessoryType = .disclosureIndicator
      return cell
    } else {
      let cell = tableView.dequeueCell(RequestCell.self, for: indexPath)
      cell.populate(request: request)
      cell.accessoryType = .disclosureIndicator
      return cell
    }
  }

  public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
}


extension RequestsViewController {
  public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    openRequestDetailVC(request: filteredRequests[indexPath.item])
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

// MARK: - UISearchResultsUpdating Delegate
extension RequestsViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    tableView.reloadData()
  }
}
