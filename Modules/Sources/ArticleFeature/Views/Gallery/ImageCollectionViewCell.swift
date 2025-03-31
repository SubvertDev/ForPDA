//
//  ImageCollectionViewCell.swift
//  ArticleFeature
//
//  Created by Виталий Канин on 12.03.2025.
//

import SwiftUI
import Nuke
import NukeUI

class ImageCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    var onZoom: ((Bool) -> Void)?
    var onToolBar: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
        setupImageView()
        setupDoubleTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError( "init(coder:) has not been implemented" )
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.frame = contentView.bounds
        addSubview(scrollView)
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
    }
    
    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapGesture.require(toFail: doubleTapGesture)
        scrollView.addGestureRecognizer(singleTapGesture)
    }
    
    func setImage(url: URL) {
        let request = ImageRequest(url: url)

        ImagePipeline.shared.loadImage(with: request) { result in
            switch result {
            case .success(let response):
                Task { @MainActor in
                    self.imageView.image = response.image
                }
            case .failure:
                Task { @MainActor in
                    print("Error loading image")
                }
            }
        }
    }
    
    func setZoom(isZoomed: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.onZoom?(true)
            self.scrollView.setZoomScale(isZoomed ? 4.0 : 1.0, animated: true)
        }
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let scrollView = gesture.view as? UIScrollView else { return }
        let touchPoint = gesture.location(in: imageView)
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            onZoom?(true)
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: touchPoint)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            onZoom?(false)
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
    
    @objc private func handleSingleTap() {
        onToolBar?() 
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        let scrollViewSize = scrollView.bounds.size
        let width = scrollViewSize.width / scale
        let height = scrollViewSize.height / scale
        let x = center.x - (width / 2)
        let y = center.y - (height / 2)
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let isZoomed = scrollView.zoomScale > scrollView.minimumZoomScale
        onZoom?(isZoomed)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
