//
//  UICollectionView+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//
//  swiftlint:disable force_cast

import UIKit

extension UICollectionView {
        
    func register<T: UICollectionViewCell>(_ type: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.identifier)
    }
    
    func registerHeader<T: UICollectionReusableView>(_ type: T.Type) {
        register(T.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: T.identifier)
    }
    
    func registerFooter<T: UICollectionReusableView>(_ type: T.Type) {
        register(T.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: T.identifier)
    }

    func reuse<T: UICollectionViewCell>(_ type: T.Type, _ indexPath: IndexPath) -> T {
        dequeueReusableCell(withReuseIdentifier: T.identifier, for: indexPath) as! T
    }
    
    func reuseSupplementary<T: UICollectionViewCell>(_ type: T.Type, kind: String, _ indexPath: IndexPath) -> T {
        dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.identifier, for: indexPath) as! T
    }
    
    func reuseHeader<T: UICollectionReusableView>(_ type: T.Type, _ indexPath: IndexPath) -> T {
        dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: T.identifier, for: indexPath) as! T
    }
}
