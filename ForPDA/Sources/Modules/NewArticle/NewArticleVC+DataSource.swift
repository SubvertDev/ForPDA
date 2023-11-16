//
//  NewArticleVC+DataSource.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//
//  swiftlint:disable function_body_length

import UIKit

extension NewArticleVC {
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    enum Section: CaseIterable {
        case article
        case comments
    }

    enum Item: Hashable {
        case text(ArticleTextCellModel)
        case image(ArticleImageCellModel)
        case imageWithText(ArticleImageWithTextCellModel)
        case video(ArticleVideoCellModel)
        case gif(ArticleGifCellModel)
        case button(ArticleButtonCellModel)
        case bulletList(ArticleBulletListCellModel)
        // case quiz?
        case comments(ArticleCommentsCellModel)
    }
    
    // MARK: - Make
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self else { return UICollectionViewCell() }
            switch itemIdentifier {
            case .text(let model):
                let cell = collectionView.reuse(ArticleTextCell.self, indexPath)
                cell.configure(model: model)
                return cell
            case .image(let model):
                let cell = collectionView.reuse(ArticleImageCell.self, indexPath)
                cell.configure(model: model)
                return cell
            case .imageWithText(let model):
                let cell = collectionView.reuse(ArticleImageWithTextCell.self, indexPath)
                cell.configure(model: model)
                return cell
            case .video(let model):
                let cell = collectionView.reuse(ArticleVideoCell.self, indexPath)
                cell.configure(model: model)
                return cell
            case .gif(let model):
                let cell = collectionView.reuse(ArticleGifCell.self, indexPath)
                cell.configure(model: model)
                return cell
            case .button(let model):
                let cell = collectionView.reuse(ArticleButtonCell.self, indexPath)
                cell.configure(model: model)
                return cell
            case .bulletList(let model):
                let cell = collectionView.reuse(ArticleBulletListCell.self, indexPath)
                cell.configure(model: model)
                return cell
            case .comments(let model):
                let cell = collectionView.reuse(ArticleCommentsCell.self, indexPath)
                cell.configure(model: model)
                cell.delegate = self
                return cell
            }
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self, kind == UICollectionView.elementKindSectionHeader else { return nil }
            
            switch indexPath.section {
            // Article Header
            case 0:
                let view = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ArticleHeaderReusableView.identifier,
                    for: indexPath
                ) as? ArticleHeaderReusableView
                
                let model = ArticleHeaderViewModel(
                    imageUrl: presenter.article.info?.imageUrl,
                    title: presenter.article.info?.title
                )
                
                view?.configure(model: model)
                
                return view
                
            // Comments Header
            case 1:
                let view = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ArticleCommentsReusableView.identifier,
                    for: indexPath
                ) as? ArticleCommentsReusableView
                
                let model = ArticleCommentsReusableViewModel(
                    amount: Int(presenter.article.info?.commentAmount ?? "0") ?? 0
                )
                
                view?.configure(model: model)
                view?.delegate = self
                commentsHeaderInput = view
                
                return view
                
            default:
                return nil
            }

        }
        
        return dataSource
    }
    
    // MARK: - Update
    
    func update(elements: [ArticleElement] = [], comments: [Comment] = [], animated: Bool = true) {
        var snapshot = Snapshot()
        
        if !comments.isEmpty {
            snapshot.appendSections(Section.allCases)

            let model = ArticleCommentsCellModel(comments: comments)
            let commentsItem = Item.comments(model)
            snapshot.appendItems([commentsItem], toSection: .comments)
        } else {
            snapshot.appendSections([.article])
        }
        
        for element in elements {
            switch element {
            case let item as TextElement:
                let model = ArticleTextCellModel(
                    text: item.text,
                    isHeader: item.isHeader,
                    isQuote: item.isQuote,
                    inList: item.inList,
                    countedListIndex: item.countedListIndex
                )
                let textItem = Item.text(model)
                snapshot.appendItems([textItem], toSection: .article)
                
            case let item as ImageElement:
                if let description = item.description {
                    let model = ArticleImageWithTextCellModel(
                        imageUrl: item.url,
                        description: description,
                        width: item.width,
                        height: item.height
                    )
                    let imageWithTextItem = Item.imageWithText(model)
                    snapshot.appendItems([imageWithTextItem], toSection: .article)
                } else {
                    let model = ArticleImageCellModel(
                        imageUrl: item.url,
                        width: item.width,
                        height: item.height
                    )
                    let imageItem = Item.image(model)
                    snapshot.appendItems([imageItem], toSection: .article)
                }
                
            case let item as VideoElement:
                let model = ArticleVideoCellModel(
                    id: item.url
                )
                let videoItem = Item.video(model)
                snapshot.appendItems([videoItem], toSection: .article)
                
            case let item as GifElement:
                let model = ArticleGifCellModel(
                    gifUrl: item.url,
                    width: item.width,
                    height: item.height
                )
                let gifItem = Item.gif(model)
                snapshot.appendItems([gifItem], toSection: .article)
                
            case let item as ButtonElement:
                let model = ArticleButtonCellModel(
                    title: item.text,
                    url: item.url
                )
                let buttonItem = Item.button(model)
                snapshot.appendItems([buttonItem], toSection: .article)
                
            case let item as BulletListParentElement:
                let model = ArticleBulletListCellModel(
                    elements: item.elements
                )
                let bulletListItem = Item.bulletList(model)
                snapshot.appendItems([bulletListItem], toSection: .article)
                
            default:
                break
            }
        }

        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
}
