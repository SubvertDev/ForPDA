//
//  ScreenWrapper.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.10.2025.
//

import SwiftUI

public struct ScreenWrapper<Content: View>: View {
    
    @State private var selection = 0
    private let hasBackButton: Bool
    private let content: () -> Content
    
    public init(
        hasBackButton: Bool = false,
        content: @escaping () -> Content
    ) {
        self.hasBackButton = hasBackButton
        self.content = content
    }
    
    public var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                content()
                    .toolbar {
                        if hasBackButton {
                            ToolbarItem(placement: .navigation) {
                                Image(systemSymbol: .chevronLeft)
                            }
                        }
                    }
            }
            .tabItem { Label(String("1"), systemSymbol: .docTextImage) }
            .tag(1)
            
            Text(String("2"))
                .tabItem { Label(String("2"), systemSymbol: .starBubble) }
                .tag(2)
            
            Text(String("3"))
                .tabItem { Label(String("3"), systemSymbol: .bubbleLeftAndBubbleRight) }
                .tag(3)
            
            Text(String("4"))
                .tabItem { Label(String("4"), systemSymbol: .personCropCircle) }
                .tag(4)
        }
    }
}
