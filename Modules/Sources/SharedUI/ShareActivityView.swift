//
//  ShareActivityView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import SwiftUI

public struct ShareActivityView: UIViewControllerRepresentable {

    public var url: URL
    public var onDismiss: (Bool) -> Void
    
    public init(
        url: URL,
        onDismiss: @escaping (Bool) -> Void
    ) {
        self.url = url
        self.onDismiss = onDismiss
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<ShareActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.modalPresentationStyle = .pageSheet
        controller.completionWithItemsHandler = { _, success, _, _ in
            onDismiss(success)
        }
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareActivityView>) {}

}
