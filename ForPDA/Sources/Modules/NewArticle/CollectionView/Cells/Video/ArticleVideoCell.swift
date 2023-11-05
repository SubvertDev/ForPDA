//
//  ArticleVideoCell.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit
import YouTubePlayerKit
import Combine

final class ArticleVideoCell: UICollectionViewCell {
    
    // MARK: - Views

    private var playerController = YouTubePlayerViewController()
    private var publisher: AnyCancellable?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Functions
    
    func configure(model: ArticleVideoCellModel) {
        if let source = playerController.player.source, source.id == model.id {
            // Keep playing?
        } else {
            // (todo) (important) For some reason video starts playing by itself
            // Quick hack to stop `some` videos from autoplaying
            publisher = playerController.player
                .objectWillChange
                .sink { [weak self] _ in
                    guard let self else { return }
                    if playerController.player.state == nil {
                        playerController.player.stop()
                    }
                }
            
            playerController.player.source = .video(id: model.id)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        publisher?.cancel()
    }
    
    deinit {
        publisher?.cancel()
    }
    
}

// MARK: - Layout

extension ArticleVideoCell {
    
    private func addSubviews() {
        contentView.addSubview(playerController.view)
    }
    
    private func makeConstraints() {
        let screenWidth = UIScreen.main.bounds.width
        let height = (Double(9) / 16) * screenWidth
        playerController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(height).priority(999)
        }
    }
    
}
