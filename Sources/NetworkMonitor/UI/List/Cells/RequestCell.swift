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
    let hstack2 = UIStackView(arrangedSubviews: [methodLabel, requestWeight, responseWeight, durationLabel, UIView()])
    hstack2.spacing = 32
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

  func populate(request: RequestModel){
    let status = StatusModel(request: request)
    codeIndicatorView.layer.cornerRadius = 6
    methodLabel.text = request.method?.uppercased()

    codeIndicatorView.backgroundColor = status.tint
    codeLabel.textColor = status.tint
    codeLabel.text = status.title

    urlLabel.text = request.url
    durationLabel.setIconAndText(icon: "clock", text: request.duration.formattedMilliseconds)
    requestWeight.setIconAndText(icon: "arrow.up", text: request.requestBody?.weight ?? "0 B")
    responseWeight.setIconAndText(icon: "arrow.down", text: request.responseBody?.weight ?? "0 B")

    durationLabel.isHidden = request.state == .pending
    requestWeight.isHidden = request.state == .pending
    responseWeight.isHidden = request.state == .pending

    dateLabel.text = request.date.stringWithFormat(dateFormat: "HH:mm:ss")
  }
}
