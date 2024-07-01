//
//  ArticleRowView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import NukeUI
import Models

struct ArticleRowView: View {
    
    let article: ArticlePreview
    
    private let cellPadding: CGFloat = 16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyImage(url: article.imageUrl) { state in
                if let image = state.image { image.resizable().scaledToFill() }
            }
            .frame(width: UIScreen.main.bounds.width - cellPadding * 2,
                   height: UIScreen.main.bounds.width * 0.5 - cellPadding * 2)
            .clipped()
            .cornerRadius(16)
            
            Text(article.title)
                .font(.title3)
                .fontWeight(.medium)
            
            Text(article.description)
                .font(.subheadline)
                .fontWeight(.light)
                .lineLimit(3)
            
            HStack {
                Text(article.authorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemSymbol: .message)
                        .foregroundStyle(.gray)
                    
                    Text(String(article.commentsAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                }
                .padding(.trailing, 8)
                
                Text(article.date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, cellPadding)
    }
}
