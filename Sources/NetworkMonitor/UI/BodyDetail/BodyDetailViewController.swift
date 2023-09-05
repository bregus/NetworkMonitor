import UIKit

final class BodyDetailViewController: UIViewController {
  private let textView: UITextView = UITextView()
  
  private lazy var imageView: ImageScrollView = ImageScrollView(frame: view.bounds)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never
    setupNavigationItems()
    addTextView()
  }

  private func setupNavigationItems() {
    let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareContent))
    navigationItem.rightBarButtonItems = [shareButton]
  }

  func addTextView() {
    view.addSubview(textView)
    textView.dataDetectorTypes = .link
    textView.isEditable = false
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
      textView.removeFromSuperview()
      addImageView()
      imageView.setImage(image)
    } else {
      textView.text = body.prettyPrintedJSONString
    }
  }

  func setText(_ text: String) {
    textView.text = text
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
