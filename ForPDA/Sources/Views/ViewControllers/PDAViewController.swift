//
//  PDAViewController.swift
//  ForPDA
//
//  Created by Subvert on 4.12.2022.
//
//  swiftlint:disable force_cast

import UIKit
import Factory

class PDAViewControllerWithView<CustomView: UIView>: PDAViewController {
    
    var myView: CustomView {
        return view as! CustomView
    }

    override func loadView() {
        view = CustomView()
    }
    
}

class PDAViewController: UIViewController {

    @LazyInjected(\.settingsService) private var settings

    init() {
        super.init(nibName: nil, bundle: nil)
        
        changeNightModeBackgroundColor()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(changeNightModeBackgroundColor(_:)),
            name: .nightModeBackgroundColorDidChange, object: nil
        )
    }
    
    @objc private func changeNightModeBackgroundColor(_ notification: Notification = .init(name: .nightModeBackgroundColorDidChange)) {
        
        var color: AppNightModeBackgroundColor
        if let object = notification.object as? AppNightModeBackgroundColor {
            color = object
        } else {
            color = settings.getAppBackgroundColor()
        }
        
        view.backgroundColor = color == .dark ? R.color.nearBlack() : .systemBackground
        for subview in view.subviews {
            if let tableView = subview as? UITableView {
                if tableView.style == .plain {
                    tableView.backgroundColor = color == .dark ? R.color.nearBlack() : .systemBackground
                } else {
                    tableView.backgroundColor = color == .dark ? R.color.nearBlackGrouped() : .systemGroupedBackground
                }
            }
            if let collectionView = subview as? UICollectionView {
                collectionView.backgroundColor = color == .dark ? R.color.nearBlack() : .systemBackground
            }
        }
    }

    @available(*, unavailable, message: "Loading this view controller from a nib is unsupported.")
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init()
    }

    @available(*, unavailable, message: "Loading this view controller from a nib is unsupported.")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
