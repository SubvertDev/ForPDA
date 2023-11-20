//
//  UIViewController+Ext.swift
//  ForPDA
//
//  Created by tikh on 16.05.2023.
//

import UIKit
import RouteComposer
import SFSafeSymbols


protocol Alertable: AnyObject {
    func showAlert(title: String, message: String)
}

extension UIViewController: Alertable {
    
    // MARK: - Setting TabBar Title & Name
    
    func setTabBarItemWith(title: String, image: UIImage, selectedImage: UIImage) {
        tabBarItem.title = title
        tabBarItem.image = image
        tabBarItem.selectedImage = selectedImage
    }
    
    func setTabBarItemWith(title: String, sfSymbol: SFSymbol) {
        tabBarItem.title = title
        tabBarItem.image = UIImage(systemSymbol: sfSymbol)
        tabBarItem.selectedImage = UIImage(systemSymbol: sfSymbol)
            .withTintColor(.label, renderingMode: .alwaysOriginal)
    }

    // MARK: - Scroll To Top functionality
    
    func scrollToTop() {
        func scrollToTop(view: UIView?) {
            guard let view = view else { return }
            
            switch view {
            case let collectionView as UICollectionView:
                if collectionView.scrollsToTop {
                    collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    return
                }
            case let tableView as UITableView:
                if tableView.scrollsToTop {
                    tableView.setContentOffset(.zero, animated: true)
                    return
                }
            default:
                break
            }
            
            for subView in view.subviews {
                scrollToTop(view: subView)
            }
        }
        
        scrollToTop(view: view)
    }
    
    var isScrolledToTop: Bool {
        for subview in view.subviews {
            switch subview {
                
            case let collectionView as UICollectionView:
                return (collectionView.contentOffset.y == 0)
                
            case let tableView as UITableView:
                return (tableView.contentOffset.y == 0)
                
            default:
                break
            }
        }
        return true
    }
    
    func showAlert(title: String, message: String) {
        Task { @MainActor in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: R.string.localizable.ok(), style: .default)
            alert.addAction(okAction)
            present(alert, animated: true)
        }
    }
}
