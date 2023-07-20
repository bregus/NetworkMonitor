import UIKit

@available(iOS 13, *)
final class LogRequestCell: UITableViewCell {
  private let methodLabel: UILabel = UILabel()
  private let dateLabel: UILabel = UILabel()
  private let urlLabel: UILabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    let hstack = UIStackView(arrangedSubviews: [methodLabel, UIView(), dateLabel])
    hstack.spacing = 4
    let vstack = UIStackView(arrangedSubviews: [hstack, urlLabel])
    vstack.spacing = 8
    vstack.axis = .vertical

    methodLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    dateLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    urlLabel.font = .systemFont(ofSize: 14, weight: .medium)

    contentView.addSubview(vstack)
    vstack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      vstack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      vstack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
      vstack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
      vstack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])

    methodLabel.textColor = .secondaryLabel
    dateLabel.textColor = .secondaryLabel
    urlLabel.numberOfLines = 0
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func populate(request: RequestRepresentable){
    methodLabel.text = request.scheme?.uppercased()
    urlLabel.text = request.host
    dateLabel.text = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
  }
}
