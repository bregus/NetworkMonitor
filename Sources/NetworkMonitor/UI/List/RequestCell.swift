import UIKit

@available(iOS 13, *)
final class RequestCell: UITableViewCell {
  private let codeIndicatorView: UIView = UIView()
  private let methodLabel: UILabel = UILabel()
  private let codeLabel: UILabel = UILabel()
  private let durationLabel: UILabel = UILabel()
  private let dateLabel: UILabel = UILabel()
  private let urlLabel: UILabel = UILabel()
  private let requestWeight: UILabel = UILabel()
  private let responseWeight: UILabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    let hstack = UIStackView(arrangedSubviews: [codeIndicatorView, codeLabel, UIView(), dateLabel])
    hstack.spacing = 4
    let hstack2 = UIStackView(arrangedSubviews: [methodLabel, UIView(), requestWeight, responseWeight, durationLabel])
    hstack2.spacing = 8
    let vstack = UIStackView(arrangedSubviews: [hstack, urlLabel, hstack2])
    vstack.spacing = 8
    vstack.axis = .vertical

    methodLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    codeLabel.font = .systemFont(ofSize: 14, weight: .bold)
    durationLabel.font = .systemFont(ofSize: 12)
    dateLabel.font = .systemFont(ofSize: 12, weight: .semibold)
    urlLabel.font = .systemFont(ofSize: 14, weight: .medium)
    requestWeight.font = .systemFont(ofSize: 12, weight: .medium)
    responseWeight.font = .systemFont(ofSize: 12, weight: .medium)

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

    methodLabel.textColor = .secondaryLabel

    requestWeight.textColor = .init(rgb: 0x909097)
    responseWeight.textColor = .init(rgb: 0x909097)
    durationLabel.textColor = .init(rgb: 0x909097)

    dateLabel.textColor = .secondaryLabel
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
    requestWeight.setIconAndText(icon: "arrow.up", text: request.requestBody?.weight ?? "0 KB")
    responseWeight.setIconAndText(icon: "arrow.down", text: request.responseBody?.weight ?? "0 KB")
    
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
    durationLabel.setIconAndText(icon: "clock", text: request.duration?.formattedMilliseconds() ?? "-")
    dateLabel.text = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
  }
}
