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
    let onVoteButtonTapped: ([String: [Int]]) -> Void
    
    @State private var showVoteResultsButtonTapped = false
    @State private var selections: [String: Set<Int>] = [:]
    
    init(
        poll: Topic.Poll,
        onVoteButtonTapped: @escaping ([String: [Int]]) -> Void
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
                        
                        if showVoteResultsButtonTapped {
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
            
            PollActionButtons()
        }
        .padding(16)
    }
    
    // MARK: - Poll Action Buttons
    
    @ViewBuilder
    private func PollActionButtons() -> some View {
        HStack {
            Button {
                if showVoteResultsButtonTapped {
                    showVoteResultsButtonTapped = false
                } else {
                    // TODO: Implement selection data sending...
                }
            } label: {
                Text("Vote", bundle: .module)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
            }
            .foregroundStyle(tintColor)
            .background(tintColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Spacer()
            
            if !showVoteResultsButtonTapped {
                Button {
                    showVoteResultsButtonTapped = true
                } label: {
                    Text("Show results", bundle: .module)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                }
                .foregroundStyle(tintColor)
                .background(tintColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
                            get: { isSelected(option.name, choice.id) },
                            set: { isSelected in
                                withAnimation {
                                    updateMultiSelections(option.name, choice.id, isSelected)
                                }
                            }
                        )) {}
                        .toggleStyle(CheckBoxToggleStyle())
                    } else {
                        Button {
                            withAnimation {
                                selections[option.name] = Set([choice.id])
                            }
                        } label: {
                            if isSelected(option.name, choice.id) {
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
    
    private func isSelected(_ option: String, _ choiceId: Int) -> Bool {
        return if selections[option] != nil {
            selections[option]!.contains(choiceId)
        } else { false }
    }

    private func updateMultiSelections(_ option: String, _ choiceId: Int, _ isSelected: Bool) {
        if selections[option] != nil {
            if isSelected {
                selections[option]!.insert(choiceId)
            } else {
                selections[option]!.remove(choiceId)
            }
        } else {
            selections[option] = Set([choiceId])
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
