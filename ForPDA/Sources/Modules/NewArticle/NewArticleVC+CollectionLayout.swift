//
//  NewArticleVC+CollectionLayout.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit

extension NewArticleVC {
    
    func createLayout() -> UICollectionViewLayout {
        
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            
            // Cells sizes
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(150)
                )
            )
            item.edgeSpacing = .init(
                leading: .fixed(0), top: .fixed(16),
                trailing: .fixed(0), bottom: .fixed(16)
            )
            
            let containerGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(1)
                ),
                subitems: [item]
            )
            
            let section = NSCollectionLayoutSection(group: containerGroup)
            
            // Headers sizes
            let headerSize: NSCollectionLayoutSize
            
            if sectionIndex == 0 {
                headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(0.6)
                )
            } else if sectionIndex == 1 {
                headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(42)
                )
            } else {
                headerSize = NSCollectionLayoutSize(widthDimension: .absolute(0), heightDimension: .absolute(0))
            }
            
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [sectionHeader]
            
            return section
            
        }
        return layout
    }
    
}
