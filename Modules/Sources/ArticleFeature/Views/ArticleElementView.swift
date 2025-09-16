//
//  ArticleElementView.swift
//
//
//  Created by Ilia Lubianoi on 03.07.2024.
//

import SwiftUI
import ComposableArchitecture
import NukeUI
import SkeletonUI
import YouTubePlayerKit
import SharedUI
import Models
import GalleryFeature

struct ArticleElementView: View {
    
    @Environment(\.tintColor) private var tintColor
    @Environment(\.openURL) private var openURL
    @State private var gallerySelection: Int = 0
    @State private var pollSelection: ArticlePoll.Option?
    @State private var pollSelections: Set<ArticlePoll.Option> = .init()
    @State private var showFullScreenGallery = false
    @State private var selectedImageID = 0
    
    private var hasSelection: Bool {
        return pollSelection != nil || !pollSelections.isEmpty
    }
    
    let element: ArticleElement
    let isShowingVoteResults: Bool
    let isUploadingPollVote: Bool
    var onPollVoteButtonTapped: (Int, [Int]) -> Void
    var onLinkInTextTapped: (URL) -> Void
    
    init(
        element: ArticleElement,
        isShowingVoteResults: Bool = false,
        isUploadingPollVote: Bool = false,
        onPollVoteButtonTapped: @escaping (Int, [Int]) -> Void = { _, _ in },
        onLinkInTextTapped: @escaping (URL) -> Void = { _ in }
    ) {
        self.element = element
        self.isShowingVoteResults = isShowingVoteResults
        self.isUploadingPollVote = isUploadingPollVote
        self.onPollVoteButtonTapped = onPollVoteButtonTapped
        self.onLinkInTextTapped = onLinkInTextTapped
    }
    
    var body: some View {
        switch element {
        case let .text(element):
            text(element)
                        
        case let .image(element):
            image(element)
                        
        case let .gallery(element):
            gallery(element)
                        
        case let .video(element):
            video(element)
                        
        case let .gif(element):
            GifView(url: element.url) // TODO: Add skeleton?
                        
        case let .button(element):
            button(element)
                        
        case let .bulletList(element):
            bulletList(element)
                        
        case let .table(element):
            table(element)
            
        case let .poll(element):
            poll(element)
            
        case let .advertisement(elements):
            advertisement(elements)
        }
    }
    
    // MARK: - Text
    
    @ViewBuilder
    private func text(_ element: TextElement) -> some View {
        Text(element.text.asMarkdown)
            .font(element.isHeader ? .title3 : .callout)
            .foregroundStyle(Color(.Labels.primary))
            .environment(\.openURL, OpenURLAction { url in
                onLinkInTextTapped(url)
                return .handled
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, element.isQuote ? 46 : 0)
            .padding(.top, element.isHeader ? 16 : 0)
            .padding([.horizontal, .bottom], element.isQuote ? 12 : 0)
            .overlay {
                if element.isQuote {
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.Separator.secondary), lineWidth: 0.67)
                        
                        Image(.quote)
                            .resizable()
                            .frame(width: 30, height: 20)
                            .padding([.top, .leading], 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(tintColor)
                    }
                }
            }
            .padding(.horizontal, 16)
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func image(_ element: ImageElement) -> some View {
        LazyImage(url: element.url) { state in
            Group {
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Color(.systemBackground)
                }
            }
            .skeleton(with: state.isLoading, shape: .rectangle)
        }
        .frame(width: UIScreen.main.bounds.width,
               height: UIScreen.main.bounds.width * element.ratioHW)
        .clipped()
        .onTapGesture {
            showFullScreenGallery.toggle()
        }
        .fullScreenCover(isPresented: $showFullScreenGallery) {
            TabViewGallery(gallery: [element.url], selectedImageID: selectedImageID)
        }
    }
    
    // MARK: - Gallery
    
    @ViewBuilder
    private func gallery(_ element: [ImageElement]) -> some View {
        TabView {
            ForEach(Array(element.enumerated()), id: \.element) { index, imageElement in
                LazyImage(url: imageElement.url) { state in
                    Group {
                        if let image = state.image {
                            image.resizable()
                        } else {
                            Color(.systemBackground)
                        }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .aspectRatio(imageElement.ratioWH, contentMode: .fit)
                .clipped()
                .highPriorityGesture(
                    TapGesture().onEnded {
                        showFullScreenGallery.toggle()
                        selectedImageID = index
                    }
                )
            }
            .padding(.bottom, 48) // Fix against index overlaying
        }
        .frame(height: CGFloat(element.max(by: { $0.ratioHW < $1.ratioHW})!.ratioHW) * UIScreen.main.bounds.width + 48)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .padding(.bottom, -16)
        .fullScreenCover(isPresented: $showFullScreenGallery) {
            TabViewGallery(gallery: element.map{ $0.url }, selectedImageID: selectedImageID)
        }
    }
    
    // MARK: - Video
    
    @ViewBuilder
    private func video(_ element: VideoElement) -> some View {
        let player = YouTubePlayer(source: .video(id: element.id))
        YouTubePlayerView(player) { state in
            switch state {
            case .idle:
                Color(.systemBackground)
                    .skeleton(with: true, shape: .rectangle)
            case .error:
                Color(.Background.teritary)
                    .overlay {
                        Image(.imageNotLoaded)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 36)
                    }
            case .ready:
                EmptyView()
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.5625)
    }
    
    // MARK: - Button
    
    // TODO: Not used
    @ViewBuilder
    private func button(_ element: ButtonElement) -> some View {
        Button {
            openURL(element.url)
        } label: {
            Text(element.text)
        }
        .buttonStyle(.borderedProminent)
    }
    
    // MARK: - Bullet List
    
    @ViewBuilder
    private func bulletList(_ element: BulletListElement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(element.elements.enumerated()), id: \.0) { index, singleElement in
                HStack(alignment: .top, spacing: 8) {
                    switch element.type {
                    case .numeric:
                        Text(String("\(index + 1)."))
                            .font(.callout)
                            .foregroundStyle(Color(.Labels.primary))
                        
                    case .dotted:
                        Circle()
                            .foregroundStyle(Color(.Labels.primary))
                            .frame(width: 4, height: 4)
                            .padding(.top, 8)
                    }
                    
                    Text(singleElement.asMarkdown)
                        .font(.callout)
                        .foregroundStyle(Color(.Labels.primary))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Table
    
    @ViewBuilder
    private func table(_ element: TableElement) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(element.rows.enumerated()), id: \.0) { index, row in
                VStack(spacing: 4) {
                    Text(row.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(row.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                
                if index < element.rows.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Poll
    
    @ViewBuilder
    private func poll(_ element: PollElement) -> some View {
        let poll = element.poll
        VStack(spacing: 12) {
            if !poll.title.isEmpty {
                Text(poll.title)
                    .font(.headline)
                    .foregroundStyle(Color(.Labels.primary))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if isShowingVoteResults {
                VStack(spacing: 12) {
                    ForEach(poll.options, id: \.self) { option in
                        VStack(spacing: 4) {
                            Text(option.text)
                                .font(.caption)
                                .foregroundStyle(Color(.Labels.secondary))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .foregroundStyle(Color(.Background.teritary))
                                    .frame(height: 18)
                                
                                HStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .foregroundStyle(tintColor)
                                        .frame(width: (UIScreen.main.bounds.width - 32) * progressPercentage(option: option, poll: poll), height: 18)
                                    
                                    Spacer()
                                }
                                
                                Text(String("\(Int(progressPercentage(option: option, poll: poll) * 100))%"))
                                    .font(.caption2)
                                    .foregroundStyle(Color(.Labels.quaternary))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.trailing, 4)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(poll.options, id: \.self) { option in
                        HStack(spacing: 11) {
                            Button {
                                withAnimation {
                                    if poll.singleChoice {
                                        pollSelection = (option == pollSelection) ? nil : option
                                    } else {
                                        if !pollSelections.insert(option).inserted {
                                            pollSelections.remove(option)
                                        }
                                    }
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 11) {
                                    if poll.singleChoice {
                                        if option == pollSelection {
                                            ZStack {
                                                Circle()
                                                    .strokeBorder(Color(.Labels.quintuple))
                                                    .frame(width: 22, height: 22)
                                                
                                                Circle()
                                                    .foregroundStyle(tintColor)
                                                    .frame(width: 12, height: 12)
                                            }
                                            .frame(width: 22, height: 22)
                                        } else {
                                            Circle()
                                                .strokeBorder(Color(.Labels.quintuple))
                                                .frame(width: 22, height: 22)
                                        }
                                        
                                    } else {
                                        if pollSelections.contains(option) {
                                            ZStack {
                                                Circle()
                                                    .foregroundStyle(tintColor)
                                                    .frame(width: 22, height: 22)
                                                
                                                Image(systemSymbol: .checkmark)
                                                    .font(.system(size: 13.5, weight: .semibold))
                                                    .foregroundStyle(Color(.Labels.primaryInvariably))
                                                    .frame(width: 22, height: 22)
                                            }
                                            .frame(width: 22, height: 22)
                                        } else {
                                            Circle()
                                                .strokeBorder(Color(.Labels.quintuple))
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    
                                    Text(option.text)
                                        .font(.callout)
                                        .foregroundStyle(Color(.Labels.secondary))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
            }
            
            if !isShowingVoteResults {
                HStack {
                    Button {
                        if poll.singleChoice {
                            if let pollSelection {
                                onPollVoteButtonTapped(poll.id, [pollSelection.id])
                            }
                        } else {
                            if !pollSelections.isEmpty {
                                onPollVoteButtonTapped(poll.id, Array(pollSelections.map { $0.id }))
                            }
                        }
                    } label: {
                        Text("Vote", bundle: .module)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                    }
                    .foregroundStyle(voteButtonForegroundColor(poll: poll))
                    .background(voteButtonBackgroundColor(poll: poll))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Spacer()
                }
                .disabled(voteButtonDisabled())
            } else {
                Text("\(poll.totalVotes) people voted", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.teritary))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .animation(.default, value: isShowingVoteResults)
        .animation(.default, value: isUploadingPollVote)
        .padding(.horizontal, 16)
    }
    
    private func progressPercentage(option: ArticlePoll.Option, poll: ArticlePoll) -> CGFloat {
        return CGFloat(option.votes) / CGFloat(poll.totalVotes)
    }
    
    private func voteButtonForegroundColor(poll: ArticlePoll) -> Color {
        return (!hasSelection || isUploadingPollVote) ? Color(.Labels.quintuple) : tintColor
    }
    
    private func voteButtonBackgroundColor(poll: ArticlePoll) -> Color {
        return (!hasSelection || isUploadingPollVote) ? Color(.Main.greyAlpha) : tintColor.opacity(0.12)
    }
    
    private func voteButtonDisabled() -> Bool {
        if isUploadingPollVote {
            return true
        } else {
            return !hasSelection
        }
    }
    
    // MARK: - Advertisement
    
    @ViewBuilder
    private func advertisement(_ elements: [AdvertisementElement]) -> some View {
        VStack(spacing: 8) {
            ForEach(elements, id: \.self) { element in
                Button {
                    onLinkInTextTapped(element.linkUrl)
                } label: {
                    Text(element.buttonText)
                        .font(.title3)
                        .padding(16)
                        .foregroundStyle(Color(hex: element.buttonForegroundColorHex))
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: element.buttonBackgroundColorHex))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview {
    ArticleElementView(
        element: .text(.init(text: Array(repeating: "Test ", count: 30).joined(), isQuote: true))
    )
    .frame(height: 100)
}

#Preview("Quote") {
    ArticleElementView(
        element: .text(TextElement(text: "Adipisicing mollit pariatur magna ullamco mollit mollit sit quis. Pariatur irure fugiat consequat mollit aliqua pariatur cillum fugiat occaecat non fugiat id. Nostrud consequat enim elit veniam.", isQuote: true))
    )
}

#Preview("Poll") {
    ArticleElementView(
        element: .poll(
            PollElement(
                poll: ArticlePoll(
                    id: 1,
                    title: "Test",
                    flag: 1,
                    totalVotes: 1000,
                    options: [
                        ArticlePoll.Option(id: 1, text: "Test 1", votes: 1),
                        ArticlePoll.Option(id: 2, text: "Test 2", votes: 2),
                        ArticlePoll.Option(id: 3, text: "Test 3", votes: 3),
                        ArticlePoll.Option(id: 4, text: "Test 4", votes: 4),
                    ]
                )
            )
        )
    )
}

#Preview("Bullet List") {
    ArticleElementView(
        element: .bulletList(
            .init(
                type: .dotted,
                elements: ["First Element", "Second Element", "Third Element", "Fourth Element", "Fifth Element Fifth Element Fifth Element Fifth Element"]
            )
        )
    )
    .frame(height: 100)
}

#Preview("Video") {
    ArticleElementView(
        element: .video(.init(id: "xvFZjo5PgG0"))
    )
}
