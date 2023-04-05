import UIKit

@available(iOS 13, *)
final class RequestCell: UITableViewCell {
  private let codeIndicatorView: UIView = UIView()
  private let methodLabel: UILabel = UILabel()
  private let codeLabel: UILabel = UILabel()
  private let durationLabel: UILabel = UILabel()
  private let dateLabel: UILabel = UILabel()
  private let urlLabel: UILabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    let hstack = UIStackView(arrangedSubviews: [codeIndicatorView, methodLabel, codeLabel, durationLabel, dateLabel, UIView()])
    hstack.spacing = 4
    let vstack = UIStackView(arrangedSubviews: [hstack, urlLabel])
    vstack.spacing = 8
    vstack.axis = .vertical

    methodLabel.font = .systemFont(ofSize: 15, weight: .bold)
    codeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    durationLabel.font = .systemFont(ofSize: 15)
    dateLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    urlLabel.font = .systemFont(ofSize: 14, weight: .medium)

    contentView.addSubview(vstack)
    vstack.translatesAutoresizingMaskIntoConstraints = false
    codeIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      vstack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      vstack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12),
      vstack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12),
      vstack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      codeIndicatorView.heightAnchor.constraint(equalToConstant: 12),
      codeIndicatorView.widthAnchor.constraint(equalToConstant: 12)
    ])

    durationLabel.textColor = .secondaryLabel
    dateLabel.textColor = .tertiaryLabel
    urlLabel.numberOfLines = 0
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func populate(request: RequestRepresentable?){
    guard let request else {
      return
    }
    codeIndicatorView.layer.cornerRadius = 6
    methodLabel.text = request.method?.uppercased()
    codeLabel.isHidden = request.code == nil ? true : false
    codeLabel.text = request.code != nil ? String(request.code ?? 0) : "-"
    if let code = request.code {
      var color: UIColor
      switch code {
      case 200..<300:
        color = .systemGreen
      case 300..<400:
        color = .systemYellow
      case 400..<500:
        color = .systemRed
      case 500..<600:
        color = .systemRed
      default:
        color = .systemGray
      }
      codeIndicatorView.backgroundColor = color
      codeLabel.textColor = color
    } else {
      codeIndicatorView.backgroundColor = .secondaryLabel
      codeLabel.textColor = .secondaryLabel
    }
    urlLabel.text = request.url
    durationLabel.text = request.duration?.formattedMilliseconds() ?? "-"
    dateLabel.text = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
  }
}
