//
//  NewsListRowView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import NukeUI
import Models

struct NewsListRowView: View {
    
    let preview: NewsPreview
    
    private let cellPadding: CGFloat = 16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyImage(url: preview.imageUrl) { state in
                if let image = state.image { image.resizable().scaledToFill() }
            }
            .frame(width: UIScreen.main.bounds.width - cellPadding * 2,
                   height: UIScreen.main.bounds.width * 0.5 - cellPadding * 2)
            .clipped()
            .cornerRadius(16)
            
            Text(preview.title)
                .font(.title3)
                .fontWeight(.medium)
            
            Text(preview.description)
                .font(.subheadline)
                .fontWeight(.light)
                .lineLimit(3)
            
            HStack {
                Text(preview.author)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemSymbol: .message)
                        .foregroundStyle(.gray)
                    
                    Text(preview.commentAmount)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                }
                .padding(.trailing, 8)
                
                Text(preview.date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, cellPadding)
    }
}

#Preview {
    NewsListRowView(preview: .mock())
}
