import UIKit

@available(iOS 14.0, *)
final class RequestsViewController: UITableViewController {
  private var filteredRequests: [RequestRepresentable] = Storage.shared.requests

  private var searchController = UISearchController(searchResultsController: nil)
  private let requestCellIdentifier = String(describing: RequestCell.self)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Monitor"

    addNavigationItems()
    addSearchController()
    addKeyboardToolbar()
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.hidesSearchBarWhenScrolling = false

    tableView.register(RequestCell.self, forCellReuseIdentifier: RequestCell.reuseIdentifier)
    tableView.register(LogRequestCell.self, forCellReuseIdentifier: LogRequestCell.reuseIdentifier)

    NotificationCenter.default.addObserver(forName: NSNotification.Name.NewRequestNotification, object: nil, queue: nil) { [weak self] (notification) in
      DispatchQueue.main.async { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.filteredRequests = strongSelf.filterRequests(text: strongSelf.searchController.searchBar.text)
        strongSelf.tableView.reloadData()
      }
    }
  }

  //  MARK: - Search

  private func addSearchController(){
    searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.searchBar.placeholder = "Search URL"
    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  private func filterRequests(text: String?) -> [RequestRepresentable] {
    guard let searchText = text, !searchText.isEmpty else { return Storage.shared.requests }

    return Storage.shared.requests.filter {
      $0.url.range(of: searchText, options: .caseInsensitive) != nil
    }
  }

  func addKeyboardToolbar() {
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

  @objc func tapDone() {
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

  private func openRequestDetailVC(request: RequestRepresentable){
    let requestDetailVC = DetailViewController(request: request)
    navigationController?.pushViewController(requestDetailVC, animated: true)
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NewRequestNotification, object: nil)
  }
}

@available(iOS 14.0, *)
extension RequestsViewController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    filteredRequests.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let request = filteredRequests[indexPath.item]
    if request.scheme == LogLevel.analytic.rawValue {
      let cell = tableView.dequeueReusableCell(withIdentifier: LogRequestCell.reuseIdentifier, for: indexPath) as! LogRequestCell
      cell.populate(request: request)
      cell.accessoryType = .disclosureIndicator
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: RequestCell.reuseIdentifier, for: indexPath) as! RequestCell
      cell.populate(request: request)
      cell.accessoryType = .disclosureIndicator
      return cell
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }

  override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    60
  }
}

@available(iOS 14.0, *)
extension RequestsViewController {
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    openRequestDetailVC(request: filteredRequests[indexPath.item])
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

// MARK: - UISearchResultsUpdating Delegate
@available(iOS 14.0, *)
extension RequestsViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    filteredRequests = filterRequests(text: searchController.searchBar.text)
    tableView.reloadData()
  }
}
