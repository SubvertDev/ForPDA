//
//  UITableViewCell+Ext.swift
//  PriceTracker
//
//  Created by Subvert on 11.11.2022.
//
// swiftlint:disable force_cast

import UIKit

protocol Reusable {
    associatedtype CellType: UITableViewCell = Self

    static var cellIdentifier: String { get }
    static func dequeueReusableCell(in tableView: UITableView, for indexPath: IndexPath) -> CellType
}

extension Reusable where Self: UITableViewCell {

    static var cellIdentifier: String {
        return String(describing: Self.self)
    }

    static func dequeueReusableCell(in tableView: UITableView, for indexPath: IndexPath) -> CellType {
        return tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CellType
    }
}
