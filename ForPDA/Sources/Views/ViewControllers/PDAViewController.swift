//
//  PDAViewController.swift
//  ForPDA
//
//  Created by Subvert on 4.12.2022.
//
//  swiftlint:disable force_cast

import UIKit
import Factory

internal class PDAViewController<CustomView: UIView>: UIViewController {

    @Injected(\.settingsService) private var settingsService
    
    var myView: CustomView {
        return view as! CustomView
    }

    override func loadView() {
        view = CustomView()
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        
        changeDarkThemeBackgroundColor()
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeDarkThemeBackgroundColor(_:)),
                                               name: .darkThemeBackgroundColorDidChange, object: nil)
    }
    
    @objc private func changeDarkThemeBackgroundColor(_ notification: Notification = .init(name: .darkThemeBackgroundColorDidChange)) {
        
        var color: AppDarkThemeBackgroundColor
        if let object = notification.object as? AppDarkThemeBackgroundColor {
            color = object
        } else {
            color = settingsService.getAppBackgroundColor()
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
