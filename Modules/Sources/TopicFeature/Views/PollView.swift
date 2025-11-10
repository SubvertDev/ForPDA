//
//  PollView.swift
//  ForPDA
//
//  Created by Xialtal on 1.11.25.
//

import SwiftUI
import Models
import SharedUI

struct PollView: View {
    
    @Environment(\.tintColor) private var tintColor
    
    let poll: Topic.Poll
    let onVoteButtonTapped: ([Int: Set<Int>]) -> Void
    
    @State private var isSending = false
    @State private var showVoteResultsButtonTapped = false
    @State private var selections: [Int: Set<Int>] = [:]
    
    private var isVotable: Bool {
        for option in poll.options {
            if selections[option.id] == nil {
                return false
            }
            if selections[option.id] != nil,
               selections[option.id]!.isEmpty {
                return false
            }
        }
        return true
    }
    
    init(
        poll: Topic.Poll,
        onVoteButtonTapped: @escaping ([Int: Set<Int>]) -> Void
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
            
            VStack(spacing: 12) {
                ForEach(poll.options, id: \.self) { option in
                    VStack(spacing: 8) {
                        Text(option.name)
                            .font(.subheadline)
                            .foregroundStyle(Color(.Labels.primary))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if showVoteResultsButtonTapped || poll.voted {
                            OptionChoices(choices: option.choices)
                        } else {
                            OptionChoicesSelect(option: option)
                        }
                    }
                }
            }
            
            Text("\(poll.totalVotes) people voted", bundle: .module)
                .font(.caption)
                .foregroundStyle(Color(.Labels.teritary))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !poll.voted {
                PollActionButtons()
            }
        }
        .padding(16)
    }
    
    // MARK: - Poll Action Buttons
    
    @ViewBuilder
    private func PollActionButtons() -> some View {
        HStack {
            Button {
                if showVoteResultsButtonTapped {
                    withAnimation {
                        showVoteResultsButtonTapped = false
                    }
                } else {
                    isSending = true
                    onVoteButtonTapped(selections)
                }
            } label: {
                Text("Vote", bundle: .module)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
            }
            .foregroundStyle(voteButtonForegroundColor())
            .background(voteButtonBackgroundColor())
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .disabled(!showVoteResultsButtonTapped && !isVotable)
            
            Spacer()
            
            if !showVoteResultsButtonTapped {
                Button {
                    withAnimation {
                        showVoteResultsButtonTapped = true
                    }
                } label: {
                    Text("Show results", bundle: .module)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                }
                .foregroundStyle(isSending ? Color(.Labels.quintuple) : tintColor)
                .background(isSending ? Color(.Main.greyAlpha) : tintColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(isSending)
            }
        }
    }
    
    // MARK: - Option Choices Select
    
    @ViewBuilder
    private func OptionChoicesSelect(option: Topic.Poll.Option) -> some View {
        ForEach(option.choices, id: \.self) { choice in
            VStack(spacing: 4) {
                HStack(alignment: .top, spacing: 11) {
                    if option.several {
                        Toggle(isOn: Binding(
                            get: { isSelected(option.id, choice.id) },
                            set: { isSelected in
                                withAnimation {
                                    updateMultiSelections(option.id, choice.id, isSelected)
                                }
                            }
                        )) {}
                        .toggleStyle(CheckBoxToggleStyle())
                    } else {
                        Button {
                            withAnimation {
                                selections[option.id] = Set([choice.id])
                            }
                        } label: {
                            if isSelected(option.id, choice.id) {
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
                        }
                    }
                    
                    Text(choice.name)
                        .font(.callout)
                        .foregroundStyle(Color(.Labels.secondary))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - Option Choices Display
    
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
    
    private func voteButtonForegroundColor() -> Color {
        return (!isVotable && !showVoteResultsButtonTapped || isSending) ? Color(.Labels.quintuple) : tintColor
    }
    
    private func voteButtonBackgroundColor() -> Color {
        return (!isVotable && !showVoteResultsButtonTapped || isSending) ? Color(.Main.greyAlpha) : tintColor.opacity(0.12)
    }
    
    private func isSelected(_ optionId: Int, _ choiceId: Int) -> Bool {
        return if selections[optionId] != nil {
            selections[optionId]!.contains(choiceId)
        } else { false }
    }

    private func updateMultiSelections(_ optionId: Int, _ choiceId: Int, _ isSelected: Bool) {
        if selections[optionId] != nil {
            if isSelected {
                selections[optionId]!.insert(choiceId)
            } else {
                selections[optionId]!.remove(choiceId)
            }
        } else {
            selections[optionId] = Set([choiceId])
        }
    }
}

struct CheckBoxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button(action: {
                configuration.isOn.toggle()
            }, label: {
                if !configuration.isOn {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.Separator.secondary), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Image(systemSymbol: .checkmark)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(.white))
                        }
                }
            })
            
            configuration.label
        }
    }
}

#Preview {
    VStack {
        PollView(poll: .mock, onVoteButtonTapped: { selections in
            
        })
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
