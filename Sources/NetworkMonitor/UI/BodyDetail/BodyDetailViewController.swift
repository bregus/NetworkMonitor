import UIKit

final class BodyDetailViewController: UIViewController {
  private let textView = UITextView()
  private let imageView = UIImageView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never
    setupNavigationItems()
    setupTextView()
    setupViews()
  }

  func setBody(_ body: Data) {
    if let image = UIImage(data: body) {
      let ratio = view.frame.size.width / image.size.width
      let scaledHeight = image.size.height * ratio
      imageView.image = image.resize(to: CGSize(width: view.frame.size.width - 16, height: scaledHeight))
      imageView.isHidden = false

      if let source = CGImageSourceCreateWithData(body as CFData, nil) {
        let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [AnyHashable: Any]
        textView.attributedText = .render(metadata)
      }
    } else {
      textView.attributedText = .render(body)
    }
  }

  func setText(_ text: NSAttributedString) {
    textView.attributedText = text
  }

  func setText(_ text: String) {
    textView.text = text
  }

  private func setupNavigationItems() {
    let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareContent))
    navigationItem.rightBarButtonItems = [shareButton]
  }

  private func setupTextView() {
    textView.dataDetectorTypes = .link
    textView.isEditable = false
    textView.isScrollEnabled = false
  }

  private func setupViews() {
    imageView.isHidden = true

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    let stackView = UIStackView(arrangedSubviews: [imageView, textView])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 16
    scrollView.addSubview(stackView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8),
      scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8),
      scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
    ])
  }

  @objc private func shareContent() {
    var items: [Any]
    if let image = imageView.image {
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
