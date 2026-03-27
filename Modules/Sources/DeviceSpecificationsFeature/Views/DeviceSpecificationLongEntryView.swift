//
//  DeviceSpecificationLongEntryView.swift
//  ForPDA
//
//  Created by Xialtal on 27.03.26.
//

import SwiftUI
import SharedUI

struct DeviceSpecificationLongEntryView: View {
    
    private let title: String
    private let content: String
    private let onCancelButtonTapped: () -> Void
    
    init(
        title: String,
        content: String,
        onCancelButtonTapped: @escaping () -> Void
    ) {
        self.title = title
        self.content = content
        self.onCancelButtonTapped = onCancelButtonTapped
    }
    
    var body: some View {
        ScrollView {
            Text(verbatim: content)
                .padding(.top, 24)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if !isLiquidGlass {
                Color(.Background.primary)
            }
        }
        ._toolbarTitleDisplayMode(.inline)
        .modifier(NavigationTitle(title: title))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onCancelButtonTapped()
                } label: {
                    if isLiquidGlass {
                        Image(systemSymbol: .xmark)
                    } else {
                        Image(systemSymbol: .xmark)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(.Labels.teritary))
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color(.Background.quaternary))
                                    .clipShape(Circle())
                            )
                    }
                }
            }
        }
    }
    
    @available(iOS, deprecated: 26.0)
    private struct NavigationTitle: ViewModifier {
        let title: String
        
        func body(content: Content) -> some View {
            if isLiquidGlass {
                content
                    .navigationTitle(Text(verbatim: title))
            } else {
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Text(verbatim: title)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
            }
        }
    }
}
