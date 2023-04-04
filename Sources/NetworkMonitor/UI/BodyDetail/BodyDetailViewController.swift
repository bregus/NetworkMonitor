import UIKit

@available(iOS 13, *)
final class BodyDetailViewController: UIViewController {
  private let textView = UITextView()
  private var searchController: UISearchController?
  private var highlightedWords: [NSTextCheckingResult] = []
  private var indexOfWord: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationItems()
    addSearchController()
    navigationItem.largeTitleDisplayMode = .never

    view.backgroundColor = .systemBackground
    view.addSubview(textView)
    textView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      textView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      textView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
  }

  private func setupNavigationItems() {
    //      let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareContent(_:)))
    let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(showSearch))
    navigationItem.rightBarButtonItems = [searchButton]//, shareButton]
  }

  @objc func showSearch() {
    searchController?.isActive.toggle()
  }

  func addSearchController(){
    searchController = UISearchController(searchResultsController: nil)
    searchController?.searchResultsUpdater = self
    searchController?.searchBar.returnKeyType = .done
    searchController?.searchBar.delegate = self

    searchController?.obscuresBackgroundDuringPresentation = false
    searchController?.searchBar.placeholder = "Search"

    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  func setBody(_ body: Data?) {
    let json = try? JSONSerialization.jsonObject(with: body ?? Data(), options: .mutableContainers)
    let attr = NSMutableAttributedString()
    attr.append(json ?? String(data: body ?? Data(), encoding: .utf8))
    textView.attributedText = attr
  }
}

@available(iOS 13, *)
extension BodyDetailViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
//    if searchController.searchBar.text?.isEmpty == false {
//      performSearch(text: searchController.searchBar.text)
//    }
//    else {
//      resetSearchText()
//    }
  }
}

@available(iOS 13, *)
extension BodyDetailViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
}
