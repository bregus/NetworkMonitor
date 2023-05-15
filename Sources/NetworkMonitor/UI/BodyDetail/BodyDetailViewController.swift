import UIKit

@available(iOS 13, *)
final class BodyDetailViewController: UIViewController {
  private let textView: UITextView = UITextView()

  private var searchController: UISearchController?
  private var highlightedWords: [NSTextCheckingResult] = []
  private var indexOfWord: Int = 0

  private lazy var imageView: ImageScrollView = ImageScrollView(frame: view.bounds)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never

    setupNavigationItems()
  }

  private func setupNavigationItems() {
    let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareContent))
    navigationItem.rightBarButtonItems = [shareButton]
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

    let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(showSearch))
    navigationItem.rightBarButtonItems?.append(searchButton)
  }

  func addTextView() {
    view.addSubview(textView)
    textView.dataDetectorTypes = .link
    textView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      textView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      textView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
  }

  func addImageView() {
    view.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      imageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
      imageView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
      imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
  }

  func setBody(_ body: Data) {
    if let image = UIImage(data: body) {
      addImageView()
      imageView.setImage(image)
    } else {
      addSearchController()
      addTextView()
      textView.text = body.prettyPrintedJSONString
    }
//    let json = try? JSONSerialization.jsonObject(with: body ?? Data(), options: .mutableContainers)
//    let attr = NSMutableAttributedString()
//    attr.append(json ?? String(data: body ?? Data(), encoding: .utf8))
//    textView.attributedText = attr
  }

  @objc private func shareContent() {
    var items: [Any]
    if let image = imageView.imageZoomView?.image {
      items = [image]
    } else if let text = textView.text {
      items = [text]
    } else {
      return
    }
    let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
    present(activity, animated: true)
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
