//
//  ContextButton.swift
//
//
//  Created by Ilia Lubianoi on 17.05.2024.
//

import SwiftUI
import SFSafeSymbols

// MARK: - Context Button

public struct ContextButton: View {
    
    public let text: String
    public let symbol: SFSymbol
    public let action: (() -> Void)
    
    public init(
        text: String,
        symbol: SFSymbol,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.symbol = symbol
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(text)
                Image(systemSymbol: symbol)
            }
        }
    }
}

// MARK: - Context Share Button
// RELEASE: - Any other way to mix Context with Share?

public struct ContextShareButton: View {
    
    @Binding public var showShareSheet: Bool
    
    public let text: String
    public let symbol: SFSymbol
    public let shareURL: URL
    public let action: (() -> Void)
    
    public init(
        text: String,
        symbol: SFSymbol,
        showShareSheet: Binding<Bool>,
        shareURL: URL,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.symbol = symbol
        self._showShareSheet = showShareSheet
        self.shareURL = shareURL
        self.action = action
    }
    
    public var body: some View {
        ContextButton(text: text, symbol: symbol, action: action)
            .onChange(of: showShareSheet) { _ in
                openShare()
            }
    }
    
    private func openShare() {
        let activityVC = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)

        if UIDevice.current.userInterfaceIdiom == .pad { // iPad crash fix
            let thisViewVC = UIHostingController(rootView: self)
            activityVC.popoverPresentationController?.sourceView = thisViewVC.view
        }

        UIApplication.shared.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .present(activityVC, animated: true)
    }
}
