//
//  LoadMoreView.swift
//  
//
//  Created by Ilia Lubianoi on 19.05.2024.
//

import SwiftUI
import SharedUI

struct LoadMoreView: View {
    var body: some View {
        HStack {
            Spacer()
            
            Text("Loading news")
                .padding(.trailing, 8)
            
            ModernCircularLoader(lineWidth: 2)
                .frame(width: 16, height: 16)
            
            Spacer()
        }
        .listRowSeparator(.hidden, edges: .bottom)
    }
}

#Preview {
    LoadMoreView()
}
