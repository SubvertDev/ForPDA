//
//  ComingSoonView.swift
//  ForPDA
//
//  Created by Xialtal on 27.02.26.
//

import SwiftUI

public struct ComingSoonView: View {
    
    // MARK: - Properties
    
    @Environment(\.tintColor) private var tintColor
    
    public let reason: LocalizedStringResource
    public let understoodButtonTapped: () -> ()
    public let closeButtonTapped: () -> ()
    
    // MARK: - Init
    
    public init(
        reason: LocalizedStringResource,
        understoodButtonTapped: @escaping () -> Void,
        closeButtonTapped: @escaping () -> Void
    ) {
        self.reason = reason
        self.understoodButtonTapped = understoodButtonTapped
        self.closeButtonTapped = closeButtonTapped
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image(systemSymbol: .hammer)
                .font(.title)
                .foregroundStyle(tintColor)
                .padding(.bottom, 8)
            
            Text(reason)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
            
            Spacer()
            
            Button {
                understoodButtonTapped()
            } label: {
                Text("Understood", bundle: .module)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(tintColor)
            .frame(height: 48)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(ignoresSafeAreaEdges: .bottom)
        }
        .background {
            VStack(spacing: 0) {
                ComingSoonTape()
                    .rotationEffect(Angle(degrees: 12))
                    .padding(.top, 32)
                
                Spacer()
                
                ComingSoonTape()
                    .rotationEffect(Angle(degrees: -12))
                    .padding(.bottom, 96)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            Button {
                closeButtonTapped()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(.Background.quaternary))
                        .frame(width: 30, height: 30)
                    
                    Image(systemSymbol: .xmark)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(.Labels.teritary))
                }
                .padding(.top, 14)
                .padding(.trailing, 16)
            }
        }
    }
    
    // MARK: - Coming Soon Tape
    
    @ViewBuilder
    private func ComingSoonTape() -> some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                Text("IN DEVELOPMENT", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Color(.Labels.primaryInvariably))
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 2, height: 26)
        .background(tintColor)
    }
}
