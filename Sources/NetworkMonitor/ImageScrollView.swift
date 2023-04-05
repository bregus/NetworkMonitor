//
//  ImageScrollView.swift
//  ScrollingApp
//
//  Created by Алексей Пархоменко on 30/09/2019.
//  Copyright © 2019 Алексей Пархоменко. All rights reserved.
//

import UIKit

class ImageScrollView: UIScrollView, UIScrollViewDelegate {

  var imageZoomView: UIImageView!

  lazy var zoomingTap: UITapGestureRecognizer = {
    let zoomingTap = UITapGestureRecognizer(target: self, action: #selector(handleZoomingTap))
    zoomingTap.numberOfTapsRequired = 2
    return zoomingTap
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    delegate = self
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    decelerationRate = UIScrollView.DecelerationRate.fast
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setImage(_ image: UIImage) {

    imageZoomView?.removeFromSuperview()
    imageZoomView = nil
    imageZoomView = UIImageView(image: image)
    addSubview(imageZoomView)

    configurateFor(imageSize: image.size)
  }

  func configurateFor(imageSize: CGSize) {
    contentSize = imageSize

    setCurrentMaxandMinZoomScale()
    zoomScale = minimumZoomScale

    imageZoomView.addGestureRecognizer(zoomingTap)
    imageZoomView.isUserInteractionEnabled = true

  }

  override func layoutSubviews() {
    super.layoutSubviews()

    centerImage()
  }

  func setCurrentMaxandMinZoomScale() {
    let boundsSize = bounds.size
    let imageSize = imageZoomView.bounds.size

    let xScale = boundsSize.width / imageSize.width
    let yScale = boundsSize.height / imageSize.height
    let minScale = min(xScale, yScale)

    var maxScale: CGFloat = 1.0
    if minScale < 0.1 {
      maxScale = 0.3
    }
    if minScale >= 0.1 && minScale < 0.5 {
      maxScale = 0.7
    }
    if minScale >= 0.5 {
      maxScale = max(1.0, minScale)
    }

    minimumZoomScale = minScale
    maximumZoomScale = maxScale
  }

  func centerImage() {
    let boundsSize = bounds.size
    var frameToCenter = imageZoomView.frame

    if frameToCenter.size.width < boundsSize.width {
      frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
    } else {
      frameToCenter.origin.x = 0
    }

    if frameToCenter.size.height < boundsSize.height {
      frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
    } else {
      frameToCenter.origin.y = 0
    }

    imageZoomView.frame = frameToCenter
  }

  // gesture
  @objc func handleZoomingTap(sender: UITapGestureRecognizer) {
    let location = sender.location(in: sender.view)
    zoom(point: location, animated: true)
  }

  func zoom(point: CGPoint, animated: Bool) {
    let currectScale = zoomScale
    let minScale = minimumZoomScale
    let maxScale = maximumZoomScale

    if (minScale == maxScale && minScale > 1) {
      return
    }

    let toScale = maxScale
    let finalScale = (currectScale == minScale) ? toScale : minScale
    let zoomRect = zoomRect(scale: finalScale, center: point)
    zoom(to: zoomRect, animated: animated)
  }

  func zoomRect(scale: CGFloat, center: CGPoint) -> CGRect {
    var zoomRect = CGRect.zero
    let bounds = bounds

    zoomRect.size.width = bounds.size.width / scale
    zoomRect.size.height = bounds.size.height / scale

    zoomRect.origin.x = center.x - (zoomRect.size.width / 2)
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2)
    return zoomRect
  }

  // MARK: - UIScrollViewDelegate

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageZoomView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    centerImage()
  }

}
