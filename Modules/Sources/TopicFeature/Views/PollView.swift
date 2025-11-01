//
//  PollView.swift
//  ForPDA
//
//  Created by Xialtal on 1.11.25.
//

import SwiftUI
import Models

struct PollView: View {
    
    @Environment(\.tintColor) private var tintColor
    
    let poll: Topic.Poll
    let onVoteButtonTapped: () -> Void
    
    @State private var showVoteResultsButtonTapped = true
    
    init(
        poll: Topic.Poll,
        onVoteButtonTapped: @escaping () -> Void
    ) {
        self.poll = poll
        self.onVoteButtonTapped = onVoteButtonTapped
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if !poll.name.isEmpty {
                Text(poll.name)
                    .font(.headline)
                    .foregroundStyle(Color(.Labels.primary))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if showVoteResultsButtonTapped {
                VStack(spacing: 12) {
                    ForEach(poll.options, id: \.self) { option in
                        VStack(spacing: 8) {
                            Text(option.name)
                                .font(.subheadline)
                                .foregroundStyle(Color(.Labels.primary))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            OptionChoices(choices: option.choices)
                        }
                    }
                }
                
                Text("\(poll.totalVotes) people voted", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.teritary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    //.padding(.horizontal, 16)
            } else {
                // TODO: implement...
                
            }
        }
        .padding(16)
    }
    
    // MARK: - Poll Option Choices
    
    @ViewBuilder
    private func OptionChoices(choices: [Topic.Poll.Choice]) -> some View {
        ForEach(choices, id: \.self) { choice in
            VStack(spacing: 4) {
                Text(choice.name)
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
                            .frame(
                                width: (UIScreen.main.bounds.width - 32) * progressPercentage(choice, poll.totalVotes),
                                height: 18
                            )
                        
                        Spacer()
                    }
                    
                    Text(String("\(Int(progressPercentage(choice, poll.totalVotes) * 100))%"))
                        .font(.caption2)
                        .foregroundStyle(Color(.Labels.quaternary))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 4)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func progressPercentage(_ choice: Topic.Poll.Choice, _ totalVotes: Int) -> CGFloat {
        return CGFloat(choice.votes) / CGFloat(totalVotes)
    }
}
