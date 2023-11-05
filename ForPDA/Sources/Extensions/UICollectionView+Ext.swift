//
//  UICollectionView+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit

extension UICollectionViewCell {
    
    static var reuseIdentifier: String {
        String(describing: self)
    }

}

extension UICollectionView {
        
    func register<T: UICollectionViewCell>(_ type: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    func reuse<T: UICollectionViewCell>(_ type: T.Type, _ indexPath: IndexPath) -> T {
        // swiftlint:disable force_cast
        dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as! T
        // swiftlint:enable force_cast
    }
}
