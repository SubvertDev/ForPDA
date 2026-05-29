//
//  GenericView.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 20.09.2025.
//

import SwiftUI
import SFSafeSymbols

public struct GenericView: View {
    
    // MARK: - Properties
    
    @State private var impactLight = false
    
    @Environment(\.tintColor) private var tintColor
    
    private let systemSymbol: SFSymbol
    private let title: LocalizedStringResource
    private let description: LocalizedStringResource?
    private let actionTitle: LocalizedStringResource?
    private let action: (() -> Void)?
    
    // MARK: - Init
    
    public init(
        systemSymbol: SFSymbol,
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        actionTitle: LocalizedStringResource? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemSymbol = systemSymbol
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(systemSymbol: systemSymbol)
                .font(.title)
                .foregroundStyle(tintColor)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            if let description {
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(Color(.Labels.teritary))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
            }
            
            if let actionTitle {
                Button {
                    impactLight.toggle()
                    action?()
                } label: {
                    Text(actionTitle)
                        .font(.body)
                        .foregroundStyle(tintColor)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.borderedProminent)
                ._sensoryFeedback(.impactLight, trigger: impactLight)
                .tint(tintColor.opacity(0.12))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Statics
    
    public static func GenericError(action: @escaping () -> Void) -> some View {
        GenericView(
            systemSymbol: .exclamationmarkTriangleFill,
            title: LocalizedStringResource("Whoops!", bundle: .module),
            description: LocalizedStringResource("Something went wrong...", bundle: .module),
            actionTitle: LocalizedStringResource("Try again", bundle: .module)
        ) {
            action()
        }
    }
}
// MARK: - Previews

#Preview {
    GenericView(
        systemSymbol: .exclamationmarkTriangleFill,
        title: "Couldn't load",
        description: "Try again later",
        actionTitle: "Try again"
    )
    .environment(\.tintColor, Color(.Theme.primary))
}
