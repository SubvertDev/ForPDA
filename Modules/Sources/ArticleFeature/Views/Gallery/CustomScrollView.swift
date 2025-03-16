//
//  CustomScrollView.swift
//  ArticleFeature
//
//  Created by Виталий Канин on 11.03.2025.
//
 
import SwiftUI
import UIKit
import Models

struct CustomScrollView: UIViewRepresentable {
    
    let imageElement: [ImageElement]
    @Binding var selectedIndex: Int
    @Binding var isZooming: Bool
    @Binding var isTouched: Bool
    @Binding var backgroundOpacity: Double
    var onClose: (() -> Void)?
    
    func makeUIView(context: Context) -> UICollectionView {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.backgroundColor = .black
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCollectionViewCell")
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleVerticalSwipe(_:)))
        panGesture.delegate = context.coordinator as any UIGestureRecognizerDelegate
        collectionView.addGestureRecognizer(panGesture)
        
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        let indexPath = IndexPath(item: selectedIndex, section: 0)
        DispatchQueue.main.async {
            uiView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate{
        var parent: CustomScrollView
        private var initialTouchPoint: CGPoint = .zero
        private var firstSwipeDirection: SwipeDirection = .none

        enum SwipeDirection {
            case horizontal
            case vertical
            case none
        }
        
        init(_ parent: CustomScrollView) {
            self.parent = parent
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return parent.imageElement.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell
            cell.setImage(url: parent.imageElement[indexPath.item].url)

            cell.onZoom = { isZooming in
                DispatchQueue.main.async {
                    self.parent.isZooming = isZooming
                }
            }
            
            cell.onToolBar = {
                DispatchQueue.main.async {
                    self.parent.isTouched.toggle()
                }
            }
            return cell
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let pageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            self.parent.selectedIndex = pageIndex
            scrollView.gestureRecognizers!.last!.isEnabled = true
            firstSwipeDirection = .none
        }
        
        @objc func handleVerticalSwipe(_ gesture: UIPanGestureRecognizer) {
            guard let collectionView = gesture.view as? UICollectionView else { return }
            guard let visibleCell = collectionView.visibleCells.first as? ImageCollectionViewCell else { return }
            let translation = gesture.translation(in: gesture.view?.superview)
            if parent.isZooming { return }
            
            switch gesture.state {
            case .began:
                initialTouchPoint = gesture.location(in: gesture.view?.superview)
            case .changed:
                if abs(translation.y) > abs(translation.x) && firstSwipeDirection == .vertical  {
                    collectionView.isScrollEnabled = false 
                    visibleCell.transform = CGAffineTransform(translationX: 0, y: translation.y)
                    self.parent.backgroundOpacity = max(0.1, 1 - Double(abs(translation.y * 5) / 700))
                    collectionView.layer.opacity = max(0.1, 1 - Float(abs(translation.y * 2.5) / 700))
                }
            case .ended, .cancelled:
                if abs(translation.y) > 150 {
                    parent.onClose?()
                    UIView.animate(withDuration: 0.6,
                                   delay: 0,
                                   usingSpringWithDamping: 0.8,
                                   initialSpringVelocity: 0.3,
                                   options: .curveEaseInOut,
                                   animations: {
                        self.parent.backgroundOpacity = 0.0
                        collectionView.layer.opacity = 0.0
                    })
                } else {
                    UIView.animate(withDuration: 0.6,
                                   delay: 0,
                                   usingSpringWithDamping: 0.8,
                                   initialSpringVelocity: 0.3,
                                   options: .curveEaseInOut,
                                   animations: {
                        visibleCell.transform = CGAffineTransform(translationX: 0, y: 0)
                        self.parent.backgroundOpacity = 1.0
                        collectionView.layer.opacity = 1.0
                    })
                }
                firstSwipeDirection = .none
                collectionView.isScrollEnabled = true
            case .failed:
                print("failed")
            case .possible:
                print("possible")
            @unknown default:
                break
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let collection = otherGestureRecognizer.view as? UICollectionView else {
                return false
            }
            
            if parent.imageElement.count == 1 {
                firstSwipeDirection = .vertical
                return true
            }
            
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)
                if firstSwipeDirection == .none {
                    if abs(velocity.x) > abs(velocity.y) {
                        firstSwipeDirection = .horizontal
                        collection.isScrollEnabled = true
                        panGesture.isEnabled = false //
                    } else if abs(velocity.x) < abs(velocity.y) {
                        firstSwipeDirection = .vertical
                        otherGestureRecognizer.isEnabled = true
                        collection.isScrollEnabled = false
                    }
                }
            }
            
            return true
        }
    }
}
