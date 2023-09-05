import UIKit

@available(iOS 13, *)
final class LogRequestCell: UITableViewCell {
  private let logLevelLabel: UILabel = UILabel()
  private let labelLabel: UILabel = UILabel()
  private let dateLabel: UILabel = UILabel()
  private let urlLabel: UILabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    let hstack = UIStackView(arrangedSubviews: [logLevelLabel, UIView(), labelLabel, dateLabel])
    hstack.spacing = 8
    let vstack = UIStackView(arrangedSubviews: [hstack, urlLabel])
    vstack.spacing = 8
    vstack.axis = .vertical

    logLevelLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    labelLabel.font = .systemFont(ofSize: 12, weight: .semibold)
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

    logLevelLabel.textColor = .secondaryLabel
    labelLabel.textColor = .secondaryLabel
    dateLabel.textColor = .secondaryLabel
    urlLabel.numberOfLines = 0
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func populate(request: RequestModel){
    logLevelLabel.text = request.scheme?.uppercased()
    labelLabel.setIconAndText(icon: "tag", text: request.host ?? "-")
    urlLabel.text = request.url
    dateLabel.text = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
  }
}
